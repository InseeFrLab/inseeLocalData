<!-- README.md is generated from README.Rmd. Please edit that file -->

# inseeLocalData

<!-- badges: start -->

[![R-CMD-check](https://github.com/InseeFrLab/inseeLocalData/workflows/R-CMD-check/badge.svg)](https://github.com/InseeFrLab/inseeLocalData/actions)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/inseeLocalData)](https://cran.r-project.org/package=inseeLocalData)
<!-- badges: end -->

L’[API ‘Données
locales’](https://api.insee.fr/catalogue/site/themes/wso2/subthemes/insee/pages/item-info.jag?name=DonneesLocales&version=V0.1&provider=insee)
permet d’accéder aux données localisées à la commune, diffusées sur
insee.fr dans la rubrique ‘chiffres détaillés’, sous forme de cubes
prédéfinis.

Les cubes prédéfinis sont ceux utilisés pour l’élaboration des tableaux
et graphiques en ligne, correspondant aux sources suivantes :
recensement de la population, état civil, répertoire des entreprises,
fichier localisé social et fiscal et des établissements et offre
d’hébergement touristique.

Ce package permet d’importer les données présentes dans l’API Données
Locales dans une liste contenant 4 objets :

  - les données statistiques ;
  - les modalités de chaque variable ;
  - l’information sur la zone demandée ;
  - l’information sur la source et le jeu de données demandé.

Pour plus d’information sur le fonctionnement de l’API DDL, vous pouvez
vous référer à la documentation de l’API (dans l’onglet Documentation) :

  - Service Web DDL.pdf : Document présentant les fonctionnalités du
    service web mis à disposition par l’Insee pour l’accès aux données
    locales. Il est vivement conseillé de lire cette documentation avant
    d’utiliser l’API.
  - Pour chaque source, un fchier Excel documentant toute l’information
    présente dans l’API est mis à disposition.

## Installation

Vous pouvez installer la version de développement depuis GitHub en exécutant :

``` r
remotes::install_github("inseefrlab/inseeLocalData")
```

## Utilisation

Dans les différents exemples, il est nécessaire d’avoir généré
préalablement un jeton sur le catalogue des API. Ensuite plusieurs
possibilités s’offrent à vous :

  - Remplacer jeton par la valeur du jeton généré sur le catalogue des
    API ;
  - Générer une fenêtre dans laquelle vous pouvez renseigner le jeton
    généré sur le catalogue des API (.rs.askForPassword(“jeton:”) ;
  - Modifier le fichier .Renviron en ajoutant une ligne jeton = “la
    valeur du jeton genere sur le catalogue des API”. Pour accéder
    facilement au fichier .Renviron, vous pouvez utiliser la commande
    usethis::edit\_r\_environ(“user”). Il est nécessaire de redémarer R
    après avoir fait la modification. Attention, ce paramètre doit être
    mis a jour à chaque fois qu’un nouveau jeton est généré.

### Exemple d’utilisation simple :

Cet exemple permet d’utiliser l’API pour un croisement et un code
géographique.

``` r
library(inseeLocalData)

croisement <- "NA5_B-ENTR_INDIVIDUELLE"
jeu_donnees <- "GEO2017REE2017"
nivgeo <- "COM"
codgeo <- "51108"
modalite <- "all.all"

donneesAPI <- get_datase(jeton, jeu_donnees, croisement, modalite, nivgeo, codgeo)

donnees <- donneesAPI$donnees # pour accéder aux données
liste_code <- donneesAPI$liste_code # pour accéder aux nomenclatures
info_zone <- donneesAPI$info_zone # pour accéder aux données géographiques
source <- donneesAPI$source # pour accéder à la source
```

### Exemple d’utilisation sur plusieurs codes géographiques :

Cet exemple permet d’obtenir un résultat pour un même croisement sur
plusieurs codes géographiques. Il est nécessaire dans un premier temps
de charger une liste de codes géographiques et leurs niveaux. Dans
l’exemple, il s’agit du data.frame liste\_code.

``` r
liste_code <- data.frame(codgeo = c("200023372","74056","74143","74266","74290"), nivgeo = c("EPCI","COM","COM","COM","COM"))
croisement <- "NA5_B-ENTR_INDIVIDUELLE"
jeu_donnees <- "GEO2017REE2017"
modalite <- "all.all"

sortie <- mapply(get_datase,
                 jeton, jeu_donnees, croisement, 
                 modalite, liste_code$nivgeo, liste_code$codgeo,USE.NAMES = TRUE)

donnees <- NULL
info_zone <- NULL
for (i in 1:dim(sortie)[2]){
  donnees <- rbind(donnees,sortie[,i]$donnees)
  info_zone <- rbind(info_zone,sortie[,i]$info_zone)
}

liste_code <- sortie[,1]$liste_code # la liste de code est la même pour tous les codes géographiques
source <- sortie[,1]$source # la source est la même pour tous les codes géographiques
```

### Exemple d’utilisation sur plusieurs croisements :

Cet exemple permet d’utiliser la fonction pour récupérer les données sur
plusieurs croisements (sur la même zone géographique ou une zone
différente). Les paramètres sont renseignés au préalable dans un
data.frame ‘fichier’, ayant pour variables jeu\_donnees, croisement,
modalite, nivgeo et codgeo. Le paramètre temporisation est utilisé pour
faire une pause de 2 secondes entre chaque requêtes afin de ne pas
dépasser le quota de 30 requêtes par minute.

``` r
fichier <- 'mon fichier'
sortie <- mapply(get_dataset,
               jeton, fichier$jeu_donnees, fichier$croisement, 
               fichier$modalite, fichier$nivgeo, fichier$codgeo,2,USE.NAMES = TRUE)

# pour le 1er croisement renseigné dans le fichier en entrée
donnees <- sortie[,1]$donnees # pour accéder aux données du 1er croisement renseigné dans le fichier
liste_code <- sortie[,1]$liste_code # pour accéder aux nomenclatures du 1er croisement renseigné dans le fichier
info_zone <- sortie[,1]$info_zone # pour accéder aux données géographiques du 1er croisement renseigné dans le fichier
source <- sortie[,1]$source # pour accéder à la source du 1er croisement renseigné dans le fichier
```

## Licence

Le code source de ce projet est publié sous licence GPL.
