import cv2
import numpy as np
from PIL import Image
import os

class VirtualTryOnEngine:
    def __init__(self):
        # Utilisation de OpenCV Haar Cascades
        base_path = cv2.data.haarcascades
        self.face_cascade = cv2.CascadeClassifier(os.path.join(base_path, 'haarcascade_frontalface_default.xml'))
        self.eye_cascade = cv2.CascadeClassifier(os.path.join(base_path, 'haarcascade_eye.xml'))
        
        if self.face_cascade.empty() or self.eye_cascade.empty():
            print("CRITICAL ERROR: Failed to load Haar Cascades from", base_path)
            self._initialized = False
        else:
            self._initialized = True

    def _extract_glasses_ultra(self, img):
        """
        Extraction de haute prcision via GrabCut multi-stratgie.
        Gre : Visages en fond, mains, tables, fonds blancs.
        """
        if img.shape[2] == 4:
            return img

        h, w = img.shape[:2]
        
        # 1. Pr-traitement pour identifier les zones probables
        mask = np.zeros((h, w), np.uint8) # 0=BGD, 1=FGD, 2=PR_BGD, 3=PR_FGD
        
        # Rectangle central par dfaut (on suppose les lunettes au centre)
        margin_w, margin_h = int(w*0.12), int(h*0.12)
        rect = (margin_w, margin_h, w - 2*margin_w, h - 2*margin_h)
        
        # Initialisation par rectangle
        bgdModel = np.zeros((1, 65), np.float64)
        fgdModel = np.zeros((1, 65), np.float64)
        
        # On affine le masque de dpart avec des heuristiques
        # - Les bords extrmes sont trs probablement du fond
        mask[:5, :] = cv2.GC_BGD
        mask[-5:, :] = cv2.GC_BGD
        mask[:, :5] = cv2.GC_BGD
        mask[:, -5:] = cv2.GC_BGD
        
        # - Dtection de couleur peau (YCrCb) pour marquer comme PR_BGD
        #   (Si les lunettes sont portes par une personne)
        img_ycrcb = cv2.cvtColor(img, cv2.COLOR_BGR2YCrCb)
        skin_mask = cv2.inRange(img_ycrcb, (0, 133, 77), (255, 173, 127))
        mask[skin_mask > 0] = cv2.GC_PR_BGD
        
        # - Dtection de zones trs claires (fond blanc ou reflets table)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        white_mask = cv2.threshold(gray, 245, 255, cv2.THRESH_BINARY)[1]
        # On ne marque comme fond que si c'est loin du centre
        mask[white_mask > 0] = cv2.GC_PR_BGD

        # 2. Excution de GrabCut
        # On fait 5 itrations pour une bonne prcision
        try:
            cv2.grabCut(img, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)
        except:
            # Fallback simple si GrabCut choue
            _, mask_simple = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
            mask_final = mask_simple
        else:
            # 3. Construction du masque final
            # 0 et 2 sont du fond, 1 et 3 sont de l'objet
            mask_final = np.where((mask == 2) | (mask == 0), 0, 255).astype('uint8')

        # 4. Raffinement par contours (pour boucher les trous des montures)
        contours, _ = cv2.findContours(mask_final, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        full_area = np.zeros_like(mask_final)
        cv2.drawContours(full_area, contours, -1, 255, -1)
        
        # 5. Construction de l'Alpha
        alpha = np.zeros((h, w), dtype=np.uint8)
        
        # Verres : zone pleine mais translucide
        alpha[full_area > 0] = 80 
        
        # Monture : zones qui taient initialement sombres OU fortes dans le masque
        _, frame_detail = cv2.threshold(gray, 225, 255, cv2.THRESH_BINARY_INV)
        frame_detail = cv2.bitwise_and(frame_detail, mask_final)
        
        # Opacit totale pour la monture
        alpha[frame_detail > 0] = 255
        
        # Lissage final
        alpha = cv2.GaussianBlur(alpha, (3, 3), 0)
        
        b, g, r = cv2.split(img)
        return cv2.merge([b, g, r, alpha])

    def process_try_on(self, user_image_path, glasses_image_path, output_path):
        # --- 1. CHARGEMENT ---
        try:
            from PIL import Image, ImageOps
            pil_img = Image.open(user_image_path)
            pil_img = ImageOps.exif_transpose(pil_img)
            user_img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        except:
            user_img = cv2.imread(user_image_path)

        if user_img is None: return False
        
        glasses_raw = cv2.imread(glasses_image_path, cv2.IMREAD_UNCHANGED)
        if glasses_raw is None: return False

        # --- 2. EXTRACTION ULTRA ---
        glasses_img = self._extract_glasses_ultra(glasses_raw)

        # --- 3. DÉTECTION ---
        if not self._initialized: return False
        gray_user = cv2.cvtColor(user_img, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(gray_user, 1.15, 5, minSize=(100, 100))

        if len(faces) == 0:
            cv2.imwrite(output_path, user_img)
            return False

        (x, y, w, h) = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)[0]
        roi_gray = gray_user[y:y+h, x:x+w]
        eyes = self.eye_cascade.detectMultiScale(roi_gray, 1.1, 8)
        
        if len(eyes) < 2:
            eye_center_x, eye_center_y, eye_dist, angle = x + w/2, y + h*0.38, w*0.42, 0
        else:
            eyes = sorted(eyes, key=lambda e: e[0])
            e1, e2 = eyes[0], eyes[-1]
            left_eye = np.array([x + e1[0] + e1[2]/2, y + e1[1] + e1[3]/2])
            right_eye = np.array([x + e2[0] + e2[2]/2, y + e2[1] + e2[3]/2])
            eye_dist = np.linalg.norm(right_eye - left_eye)
            eye_center_x, eye_center_y = (left_eye + right_eye) / 2
            angle = np.degrees(np.arctan2(right_eye[1] - left_eye[1], right_eye[0] - left_eye[0]))

        # --- 4. SUPERPOSITION ---
        target_width = int(eye_dist * 2.4)
        target_height = int(target_width * (glasses_img.shape[0] / glasses_img.shape[1]))
        resized = cv2.resize(glasses_img, (target_width, target_height), interpolation=cv2.INTER_LANCZOS4)
        M = cv2.getRotationMatrix2D((target_width / 2, target_height / 2), angle, 1)
        rotated = cv2.warpAffine(resized, M, (target_width, target_height), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_CONSTANT, borderValue=(0,0,0,0))

        y1, x1 = int(eye_center_y - target_height/2), int(eye_center_x - target_width/2)
        y2, x2 = y1 + target_height, x1 + target_width
        img_h, img_w, _ = user_img.shape
        ov_x1, ov_y1, ov_x2, ov_y2 = max(0, -x1), max(0, -y1), target_width - max(0, x2 - img_w), target_height - max(0, y2 - img_h)
        x1, y1, x2, y2 = max(0, x1), max(0, y1), min(img_w, x2), min(img_h, y2)

        if x2 > x1 and y2 > y1:
            overlay = rotated[ov_y1:ov_y2, ov_x1:ov_x2]
            alpha_mask = overlay[:, :, 3:] / 255.0
            user_img[y1:y2, x1:x2] = (user_img[y1:y2, x1:x2] * (1.0 - alpha_mask) + overlay[:, :, :3] * alpha_mask).astype(np.uint8)

        cv2.imwrite(output_path, user_img, [int(cv2.IMWRITE_JPEG_QUALITY), 95])
        return True
