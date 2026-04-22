# 🖼️ MATLAB Image Processing Toolkit

Un outil interactif MATLAB pour le **filtrage d'images** et la **détection de contours**, 
avec export automatique des résultats et métriques de qualité (PSNR, MSE).

---

##  Fonctionnalités

- 📂 Sélection multiple d'images (`.jpg`, `.png`, `.tif`, `.bmp`)
-  **5 méthodes de filtrage** au choix :
  - Égalisation d'histogramme (`histeq`)
  - Ajustement de contraste (`imadjust`)
  - Filtre médian (3×3)
  - Filtre Gaussien (5×5)
  - Filtre moyen (3×3)
- **Résultats:
  <img width="1622" height="915" alt="resultat_filtre" src="https://github.com/user-attachments/assets/6cda4516-f963-431f-8ddf-d3406ae0d889" />

-  **5 méthodes de détection de contours** :
  - Sobel, Prewitt, Roberts, LoG, Canny
-  Calcul automatique des métriques **MSE** et **PSNR**
-  Export des figures et images traitées en `.png`
-  Rapport CSV des métriques
-  Pipeline combiné : filtrage → détection de contours
- **Résultats:
  <img width="1622" height="945" alt="resultat edge detection " src="https://github.com/user-attachments/assets/28c430ce-878b-4398-9228-593aa499edc0" />


---

##  Prérequis

- MATLAB **R2020b** ou supérieur
- **Image Processing Toolbox**
- Compatible **MATLAB Online** (MATLAB Drive)
## Author

**Chahd Heni** — Biomedical Engineering Student  
Higher Institute of Medical Technologies of Tunis (ISTMT)  
[GitHub](https://github.com/henichahd)

---

## License

MIT License
