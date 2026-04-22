clc;
clear all;
close all;

% =========================================================
% SÉLECTION DES IMAGES — Compatible MATLAB Online
% =========================================================
fprintf('📂 Sélectionne tes images...\n');

% Sur MATLAB Online, il faut d'abord uploader dans /MATLAB Drive
% puis sélectionner depuis là
[fichiers, dossier] = uigetfile( ...
    {'*.tif;*.jpg;*.jpeg;*.png;*.bmp', 'Images (*.tif,*.jpg,*.png,*.bmp)'}, ...
    'Sélectionne une ou plusieurs images', ...
    '/MATLAB Drive/', ...         % ← Pointe directement vers MATLAB Drive
    'MultiSelect', 'on');

if isequal(fichiers, 0)
    disp('Aucune image sélectionnée.');
    return;
end

if ischar(fichiers)
    fichiers = {fichiers};
end

images = {};
for i = 1:length(fichiers)
    chemin_test = fullfile(dossier, fichiers{i});
    if exist(chemin_test, 'file')
        images{end+1} = chemin_test;
    else
        fprintf('⚠️  Fichier introuvable : %s\n', chemin_test);
    end
end

images = unique(images);

if isempty(images)
    errordlg({'Aucune image trouvable !', ...
              'Sur MATLAB Online, uploade d abord tes images', ...
              'dans MATLAB Drive via le panneau "Files" à gauche.'}, 'Erreur');
    return;
end

fprintf('\n✅ Total : %d image(s) trouvée(s).\n\n', length(images));

% =========================================================
% CHOIX DU MODE DE TRAITEMENT
% =========================================================
choix_traitement = menu('Choisissez le type de traitement', ...
    '1 - Filtrage (amélioration / débruitage)', ...
    '2 - Détection de contours (Edge Detection)', ...
    '3 - Les deux (Filtrage + Edge Detection)');

if choix_traitement == 0
    disp('Annulé.');
    return;
end

faire_filtrage = (choix_traitement == 1 || choix_traitement == 3);
faire_edge     = (choix_traitement == 2 || choix_traitement == 3);

% =========================================================
% MÉTHODES DE FILTRAGE
% =========================================================
methodes_filtre = [];
noms_filtres_all = {
    'Égalisation histogramme (histeq)', ...
    'Ajustement contraste (imadjust)', ...
    'Filtre médian (3x3)', ...
    'Filtre Gaussien (5x5)', ...
    'Filtre moyen (3x3)'
};

if faire_filtrage
    choix_filtres = listdlg( ...
        'PromptString',  'Sélectionne les filtres à appliquer :', ...
        'SelectionMode', 'multiple', ...
        'ListString',    noms_filtres_all, ...
        'ListSize', [400 160], ...
        'Name', 'Méthodes de filtrage');

    if isempty(choix_filtres)
        disp('Aucun filtre sélectionné.');
        faire_filtrage = false;
    else
        methodes_filtre = choix_filtres;
    end
end

% =========================================================
% MÉTHODES DE DÉTECTION DE CONTOURS
% =========================================================
methodes_edge = [];
noms_edge_all = {'Sobel', 'Prewitt', 'Roberts', 'Laplacian of Gaussian (LoG)', 'Canny'};

if faire_edge
    choix_edges = listdlg( ...
        'PromptString',  'Sélectionne les méthodes de détection de contours :', ...
        'SelectionMode', 'multiple', ...
        'ListString',    noms_edge_all, ...
        'ListSize', [400 160], ...
        'Name', 'Edge Detection');

    if isempty(choix_edges)
        disp('Aucune méthode edge sélectionnée.');
        faire_edge = false;
    else
        methodes_edge = choix_edges;
    end
end

if ~faire_filtrage && ~faire_edge
    errordlg('Aucun traitement sélectionné !', 'Erreur');
    return;
end

% =========================================================
% DOSSIER DE SORTIE — dans MATLAB Drive
% =========================================================
dossier_sortie = '/MATLAB Drive/resultats_traitement';
if ~exist(dossier_sortie, 'dir')
    mkdir(dossier_sortie);
    fprintf('📁 Dossier créé : %s\n', dossier_sortie);
end

% =========================================================
% TABLEAU DE MÉTRIQUES
% =========================================================
resultats_table = table();

% =========================================================
% BOUCLE DE TRAITEMENT
% =========================================================
for image_idx = 1:length(images)

    chemin = images{image_idx};
    [~, nom_fichier, ~] = fileparts(chemin);

    fprintf('🔄 [%d/%d] Traitement : %s\n', image_idx, length(images), nom_fichier);

    try
        img_originale = imread(chemin);
    catch ME
        fprintf('⚠️  Lecture échouée : %s — %s\n', nom_fichier, ME.message);
        continue;
    end

    % Conversion en niveaux de gris
    if size(img_originale, 3) == 3
        img_gris = rgb2gray(img_originale);
    elseif size(img_originale, 3) == 4
        img_gris = rgb2gray(img_originale(:,:,1:3));
    else
        img_gris = img_originale;
    end
    img_gris = im2uint8(img_gris);

    % ==========================================================
    % BLOC A : FILTRAGE
    % ==========================================================
    imgs_sel = {};
    noms_sel = {};

    if faire_filtrage && ~isempty(methodes_filtre)

        img_histeq   = histeq(img_gris);
        img_imadjust = imadjust(img_gris, stretchlim(img_gris), []);
        img_median   = medfilt2(img_gris, [3 3]);
        h_gauss      = fspecial('gaussian', [5 5], 1.0);
        img_gauss    = imfilter(img_gris, h_gauss, 'replicate');
        h_mean       = fspecial('average', [3 3]);
        img_mean     = imfilter(img_gris, h_mean, 'replicate');

        all_imgs_filtre = {img_histeq, img_imadjust, img_median, img_gauss, img_mean};
        imgs_sel = all_imgs_filtre(methodes_filtre);
        noms_sel = noms_filtres_all(methodes_filtre);
        nb_sel   = length(imgs_sel);

        % Métriques
        img_ref  = imgs_sel{end};
        mse_val  = mean(mean((double(img_gris) - double(img_ref)).^2));
        if mse_val == 0
            psnr_val = Inf;
            psnr_str = 'Inf';
        else
            psnr_val = psnr(img_ref, img_gris);
            psnr_str = sprintf('%.2f dB', psnr_val);
        end

        % Figure filtrage
        nb_total = nb_sel + 1;
        nb_cols  = min(nb_total, 4);
        nb_rows  = ceil(nb_total / nb_cols);

        fig_f = figure('Name', ['Filtrage - ' nom_fichier], ...
                       'NumberTitle', 'off', ...
                       'Position', [50 50 1300 700]);

        subplot(nb_rows, nb_cols, 1);
        imshow(img_gris);
        title('Original (Niveaux de gris)', 'FontWeight', 'bold');

        for k = 1:nb_sel
            subplot(nb_rows, nb_cols, k + 1);
            imshow(imgs_sel{k});
            title(noms_sel{k}, 'FontWeight', 'bold');
        end

        sgtitle(['Filtrage : ' nom_fichier ' | PSNR = ' psnr_str], ...
                 'FontSize', 12, 'FontWeight', 'bold');

        drawnow; pause(0.5);
        saveas(fig_f, fullfile(dossier_sortie, [nom_fichier '_filtrage.png']));
        fprintf('   💾 Figure filtrage sauvegardée.\n');

        % Sauvegarde images filtrées
        noms_suffix = {'histeq', 'imadjust', 'median', 'gauss', 'mean'};
        for k = 1:nb_sel
            suffix = noms_suffix{methodes_filtre(k)};
            imwrite(imgs_sel{k}, fullfile(dossier_sortie, [nom_fichier '_' suffix '.png']));
        end

        % Métriques table
        psnr_csv = psnr_val;
        if isinf(psnr_val), psnr_csv = NaN; end
        ligne = table({nom_fichier}, {'Filtrage'}, mse_val, psnr_csv, ...
            'VariableNames', {'Image', 'Type', 'MSE', 'PSNR_dB'});
        resultats_table = [resultats_table; ligne];

        fprintf('   ✅ [Filtrage] MSE = %.4f | PSNR = %s\n', mse_val, psnr_str);
    end

    % ==========================================================
    % BLOC B : DÉTECTION DE CONTOURS
    % ==========================================================
    imgs_edge     = {};
    noms_edge_sel = {};

    if faire_edge && ~isempty(methodes_edge)

        edge_funcs = {'sobel', 'prewitt', 'roberts', 'log', 'canny'};

        for k = 1:length(methodes_edge)
            idx_e   = methodes_edge(k);
            methode = edge_funcs{idx_e};
            nom_e   = noms_edge_all{idx_e};
            try
                img_e = edge(img_gris, methode);
                imgs_edge{end+1}     = img_e;
                noms_edge_sel{end+1} = nom_e;
            catch ME
                fprintf('   ⚠️  "%s" échouée : %s\n', nom_e, ME.message);
            end
        end

        nb_edge = length(imgs_edge);

        if nb_edge > 0
            nb_total_e = nb_edge + 1;
            nb_cols_e  = min(nb_total_e, 4);
            nb_rows_e  = ceil(nb_total_e / nb_cols_e);

            fig_e = figure('Name', ['Edge Detection - ' nom_fichier], ...
                           'NumberTitle', 'off', ...
                           'Position', [80 80 1300 700]);

            subplot(nb_rows_e, nb_cols_e, 1);
            imshow(img_gris);
            title('Original (Niveaux de gris)', 'FontWeight', 'bold');

            for k = 1:nb_edge
                subplot(nb_rows_e, nb_cols_e, k + 1);
                imshow(imgs_edge{k});
                title(noms_edge_sel{k}, 'FontWeight', 'bold', 'Color', 'blue');
            end

            sgtitle(['Détection de Contours : ' nom_fichier], ...
                     'FontSize', 12, 'FontWeight', 'bold');

            drawnow; pause(0.5);
            saveas(fig_e, fullfile(dossier_sortie, [nom_fichier '_edges.png']));
            fprintf('   💾 Figure edge sauvegardée.\n');

            noms_suffix_e = {'sobel', 'prewitt', 'roberts', 'log', 'canny'};
            for k = 1:nb_edge
                suffix_e = noms_suffix_e{methodes_edge(k)};
                imwrite(imgs_edge{k}, ...
                    fullfile(dossier_sortie, [nom_fichier '_edge_' suffix_e '.png']));
            end

            densite_edge = mean(double(imgs_edge{end}(:))) * 100;
            ligne_e = table({nom_fichier}, {'Edge Detection'}, densite_edge, NaN, ...
                'VariableNames', {'Image', 'Type', 'MSE', 'PSNR_dB'});
            resultats_table = [resultats_table; ligne_e];

            fprintf('   ✅ [Edge] %s | Densité = %.2f%%\n', ...
                    strjoin(noms_edge_sel, ', '), densite_edge);
        end
    end

    % ==========================================================
    % BLOC C : PIPELINE COMBINÉ
    % ==========================================================
    if faire_filtrage && faire_edge && ~isempty(imgs_sel) && ~isempty(imgs_edge)

        img_ref_combined = imgs_sel{end};
        try
            edge_post_filter = edge(img_ref_combined, 'canny');
        catch
            edge_post_filter = edge(img_gris, 'sobel');
        end

        fig_c = figure('Name', ['Pipeline complet - ' nom_fichier], ...
                       'NumberTitle', 'off', ...
                       'Position', [100 100 1100 400]);

        subplot(1,3,1); imshow(img_gris);
        title('Original', 'FontWeight', 'bold');

        subplot(1,3,2); imshow(img_ref_combined);
        title(['Filtré : ' noms_sel{end}], 'FontWeight', 'bold');

        subplot(1,3,3); imshow(edge_post_filter);
        title('Canny sur image filtrée', 'FontWeight', 'bold', 'Color', 'blue');

        sgtitle(['Pipeline complet : ' nom_fichier], 'FontSize', 12, 'FontWeight', 'bold');

        drawnow; pause(0.5);
        saveas(fig_c, fullfile(dossier_sortie, [nom_fichier '_pipeline_complet.png']));
    end

end  % fin boucle images

% =========================================================
% RAPPORT FINAL
% =========================================================
fprintf('\n========== RAPPORT FINAL ==========\n');
if ~isempty(resultats_table)
    disp(resultats_table);
    nom_csv = fullfile(dossier_sortie, 'rapport_metriques.csv');
    writetable(resultats_table, nom_csv);
    fprintf('📊 CSV sauvegardé : %s\n', nom_csv);
else
    disp('Aucune métrique — vérifie que les images sont bien dans MATLAB Drive.');
end

% =========================================================
% GRAPHIQUE PSNR
% =========================================================
if ~isempty(resultats_table)
    mask_filtre = strcmp(resultats_table.Type, 'Filtrage');
    table_psnr  = resultats_table(mask_filtre, :);

    if height(table_psnr) > 1
        fig_psnr = figure('Name', 'Comparaison PSNR', 'NumberTitle', 'off', ...
               'Position', [100 100 900 400]);
        bar(table_psnr.PSNR_dB, 'FaceColor', [0.2 0.5 0.8]);
        set(gca, 'XTickLabel', table_psnr.Image, 'XTick', 1:height(table_psnr));
        xtickangle(30);
        ylabel('PSNR (dB)'); xlabel('Images');
        title('Comparaison PSNR après filtrage', 'FontSize', 13);
        grid on;
        drawnow; pause(0.5);
        saveas(fig_psnr, fullfile(dossier_sortie, 'graphique_psnr.png'));
    end
end

fprintf('\n🎉 Terminé ! Résultats dans : %s\n', dossier_sortie);