from ultralytics import YOLO
import math
import cv2
import numpy as np

def get_yolo_model(model_path = "yolov8m-seg.pt"): return YOLO(model_path)

def get_and_apply_mask(yolo_model, image, object_index_list):
  h, w = image.shape[:2]  
  adjusted_h, adjusted_w = 32*math.ceil(h/32), 32*math.ceil(w/32)
  orig_img = image.cpu().numpy()
  image = cv2.resize(image.cpu().numpy(), (adjusted_w, adjusted_h))
  # image = image.transpose(2, 0, 1)[None, ...]
  image = image.astype(np.uint8)
  result = yolo_model.predict(image, classes = object_index_list, verbose=False)
  masks = result[0].masks.data.cpu().numpy()
  mask = np.logical_or.reduce(masks) if len(masks) != 0 else None
  resized_mask = cv2.resize(mask.astype(np.uint8), (w, h), interpolation=cv2.INTER_AREA) if mask is not None else None
  masked_img = cv2.bitwise_and(orig_img, orig_img, mask = resized_mask) if mask is not None else resized_mask
  return masked_img if mask is not None else None

COCO_NAMES = {u'__background__': 0,
    u'person': 1,
    u'bicycle': 2,
    u'car': 3,
    u'motorcycle': 4,
    u'airplane': 5,
    u'bus': 6,
    u'train': 7,
    u'truck': 8,
    u'boat': 9,
    u'traffic light': 10,
    u'fire hydrant': 11,
    u'stop sign': 12,
    u'parking meter': 13,
    u'bench': 14,
    u'bird': 15,
    u'cat': 16,
    u'dog': 17,
    u'horse': 18,
    u'sheep': 19,
    u'cow': 20,
    u'elephant': 21,
    u'bear': 22,
    u'zebra': 23,
    u'giraffe': 24,
    u'backpack': 25,
    u'umbrella': 26,
    u'handbag': 27,
    u'tie': 28,
    u'suitcase': 29,
    u'frisbee': 30,
    u'skis': 31,
    u'snowboard': 32,
    u'sports ball': 33,
    u'kite': 34,
    u'baseball bat': 35,
    u'baseball glove': 36,
    u'skateboard': 37,
    u'surfboard': 38,
    u'tennis racket': 39,
    u'bottle': 40,
    u'wine glass': 41,
    u'cup': 42,
    u'fork': 43,
    u'knife': 44,
    u'spoon': 45,
    u'bowl': 46,
    u'banana': 47,
    u'apple': 48,
    u'sandwich': 49,
    u'orange': 50,
    u'broccoli': 51,
    u'carrot': 52,
    u'hot dog': 53,
    u'pizza': 54,
    u'donut': 55,
    u'cake': 56,
    u'chair': 57,
    u'couch': 58,
    u'potted plant': 59,
    u'bed': 60,
    u'dining table': 61,
    u'toilet': 62,
    u'tv': 63,
    u'laptop': 64,
    u'mouse': 65,
    u'remote': 66,
    u'keyboard': 67,
    u'cell phone': 68,
    u'microwave': 69,
    u'oven': 70,
    u'toaster': 71,
    u'sink': 72,
    u'refrigerator': 73,
    u'book': 74,
    u'clock': 75,
    u'vase': 76,
    u'scissors': 77,
    u'teddy bear': 78,
    u'hair drier': 79,
    u'toothbrush': 80}
