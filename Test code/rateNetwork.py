from os import system, name
import tensorflow as tf
from tensorflow.python.keras import datasets, layers, models, utils, regularizers
from sklearn.metrics import classification_report, confusion_matrix, plot_confusion_matrix
from tensorflow.python.keras.preprocessing import image
from sklearn.externals import joblib
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import random

#from statistics import mode
import numpy as np
import cv2
import chess

gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
  # Restrict TensorFlow to only use the first GPU
  try:
    tf.config.experimental.set_visible_devices(gpus[0], 'GPU')
    logical_gpus = tf.config.experimental.list_logical_devices('GPU')
    print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPU")

    gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.5)
    gpu_options.allow_growth=True
    sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options))

  except RuntimeError as e:
    # Visible devices must be set before GPUs have been initialized
    print(e)

from vision_TFM import *
from cnn_TFM import *

def rotateImage(img,angle):

    h, w = img.shape[:2]
    center = (h/2,w/2)
    M = cv2.getRotationMatrix2D(center,angle,1)
    im_out = cv2.warpAffine(img,M,(h,w))

    return im_out

folder = "dataset1/validate"


vggmodel = models.load_model('models/final.h5')

from tensorflow.keras.optimizers import SGD

episodes = 100
learning_rate = 0.1
decay_rate = learning_rate / episodes
momentum = 0.8
opt = SGD(lr=learning_rate, momentum=momentum, decay=decay_rate, nesterov=False)

vggmodel.compile(optimizer=opt,loss='sparse_categorical_crossentropy',metrics=['accuracy'])
vggmodel.summary()


feat_vggmodel = models.Sequential()
for layer in vggmodel.layers[:-1]: # go through until last layer
    feat_vggmodel.add(layer)

clf1 = joblib.load('svm_tfm.pkl')

labels = ["-", "BB", "BK","BN","BP", "BQ", "BR", "WB", "WK","WN","WP", "WQ", "WR"]
img_max = 174
dim = (224, 224)

success = 0
success_svm = 0
success_top3 = 0
total = 0
ang = 0

system('cls')
msg = ''

correct_answer = []
cnn_result = []
svm_result = []

for lbl in labels:

    for n in range(1,img_max+1):

        try:

            file = folder +'/'+ lbl + "/im (" + str(n) +").jpg"

            img = image.load_img(file)
            img = image.img_to_array(img)
            img = cv2.resize(img,dim)
            img = np.expand_dims(img/255., axis=0)

            #img = rotateImage(img,ang)/255.

            pred = vggmodel.predict(img, batch_size = 1)
            feat = feat_vggmodel.predict(img, batch_size = 1)

            ind = np.argsort(pred)[0][-3:]

            top1 = labels[ind[2]]
            top3 = [labels[ind[0]], labels[ind[1]], labels[ind[2]]]

            if lbl == top1:
                success += 1
            if lbl in top3:
                success_top3 += 1

            dd = np.expand_dims(np.squeeze(feat), axis=0)
            pred_svm1 = clf1.predict(dd)

            top1_svm = labels[pred_svm1[0]]

            if lbl == top1_svm:
                success_svm += 1

            total +=1

            correct_answer.append(lbl)
            cnn_result.append(top1)
            svm_result.append(top1_svm)


        except:

            print("Image load error")


    system('cls')

    msg = msg + ' + '
    print('\n', msg, '\n')

print("Success rate: ", 100*success/total, "% of ", total, " images." )
print("Success rate with SVM: ", 100*success_svm/total, "% of ", total, " images." )
print("Success rate of top 3: ", 100*success_top3/total, "% of ", total, " images.\n" )

print('Confusion Matrix:\n')

cf_matrix = confusion_matrix(correct_answer, cnn_result, labels)
print("CNN Results:\n", cf_matrix)

cf_matrix_svm = confusion_matrix(correct_answer, svm_result, labels)
print("\nSVM Results:\n",cf_matrix_svm)

df_cm = pd.DataFrame(cf_matrix, columns=np.unique(labels), index = np.unique(labels))
df_cm.index.name = 'Actual'
df_cm.columns.name = 'Predicted'
df_cm.csv_path = 'confusion_matrix.csv'

df_cm_svm = pd.DataFrame(cf_matrix_svm, columns=np.unique(labels), index = np.unique(labels))
df_cm_svm.index.name = 'Actual'
df_cm_svm.columns.name = 'Predicted'
df_cm_svm.csv_path = 'confusion_matrix_svm.csv'

columns = {}
columns['Actual'] = correct_answer
columns['Predicted'] = cnn_result

df = pd.DataFrame(data = list(zip(columns['Actual'],columns['Predicted'])))
df.csv_path = 'predictions.csv'

df.to_csv(df.csv_path,index=False)
df_cm.to_csv(df_cm.csv_path, index=True)

plt.figure()
sns.heatmap(df_cm, cmap="Blues", annot=True,fmt='d',annot_kws={"size": 16})# font size

plt.figure()
sns.heatmap(df_cm_svm, cmap="Blues", annot=True,fmt='d',annot_kws={"size": 16})# font size
plt.show()
