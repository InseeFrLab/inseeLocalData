#' Fonction permettant d'importer les données de l'API 'données locales' pour un couple de paramètre
#'
#' @param jeton Access token (jeton) généré sur le catalogue des API de l'Insee
#' @param jeu_donnees code jeu de données se composant du nom de la source, du millésime des données et parfois du millésime géographique de diffusion
#' @param croisement sélection de variables (composée d'une variable ou de plusieurs)
#' @param modalite modalités souhaitées pour les variables (dans le même ordre)
#' @param nivgeo niveau géographique du code demandé
#' @param codgeo Codes géographiques souhaité
#' @param temporisation temps d'attente entre chaque requête (si utilisé dans une boucle)
#'
#' @return une liste contenant 4 data.frame. un contenant les données, métadonnées, les infos sur la zone sélectionnées et les infos sur la source
#'
#' @encoding UTF-8
#'
#' @export
#'
#' @importFrom rlang .data
#'
#' @examples
#' \donttest{
#' # Remplace jeton par la valeur du jeton genere sur le catalogue des API :
#' get_dataset(jeton,
#'          "GEO2017REE2017",
#'          "NA5_B-ENTR_INDIVIDUELLE",
#'          "all.all",
#'          "COM",
#'          "51108")
#'
#' # Genere une fenetre dans laquelle vous pouvez renseigner le jeton genere sur le catalogue des API
#' # Permet de ne pas stocker le jeton en clair dans le programme
#' get_dataset(.rs.askForPassword("jeton:"),
#'          "GEO2017REE2017",
#'          "NA5_B-ENTR_INDIVIDUELLE",
#'          "all.all",
#'          "COM",
#'          "51108")
#'
#' # Necessite la modification du fichier .Renviron en ajoutant
#' # une ligne jeton = "la valeur du jeton genere sur le catalogue des API"
#' # Pour acceder facilement au fichier .Renviron, vous pouvez
#' # utiliser la commande usethis::edit_r_environ("user")
#' # Necessite de redemarer R après avoir fait la modification
#' # Ce parametre doit etre mis a jour à chaque fois qu'un nouveau jeton est genere
#' get_dataset(Sys.getenv (jeton),
#'          "GEO2017REE2017",
#'          "NA5_B-ENTR_INDIVIDUELLE",
#'          "all.all",
#'          "COM",
#'          "51108")
#' }



get_dataset <- function(jeton, jeu_donnees, croisement, modalite, nivgeo, codgeo, temporisation = NA){

  modalite <- stringr::str_replace_all(modalite, '\\+', '%2B')

  auth_header <- httr::add_headers('Authorization'= paste('Bearer',jeton))

  res <- httr::content(httr::GET(paste0("https://api.insee.fr/donnees-locales/V0.1/donnees/geo-",
                                        croisement, "@", jeu_donnees, "/", nivgeo, "-", codgeo, ".", modalite),
                                 auth_header),
                       as="text", httr::content_type_json(), encoding='UTF-8')

  if (stringr::str_detect(res, "Invalid Credentials. Make sure you have given the correct access token")){
    print('Erreur - Jeton invalide')
  } else if (stringr::str_detect(res, "Aucune cellule ne correspond a la requ\u00eate")){
    print('Erreur - Param\u00e8tre(s) de la requ\u00eate incorrect(s)')
  }  else if (stringr::str_detect(res, "Resource forbidden ")){
    print("Erreur - Scouscription a l API donn\u00e9es locales non r\u00e9alis\u00e9e")
  }  else if (stringr::str_detect(res, "quota")==T){
    print("Erreur- Trop de requ\u00eates, faire une pause")
  } else{

    res <- jsonlite::fromJSON(res)

    if (length(as.data.frame(res$Cellule)) == 0 ){
      print('Erreur - Param\u00e8tre(s) de la requ\u00eate incorrect(s)')
    } else{

      nb_var <- stringr::str_count(croisement, "-") + 1

      zone <- res$Zone
      info_zone <- as.data.frame(cbind(zone$'@codgeo',zone$'@nivgeo',do.call("cbind", zone$Millesime)), stringsAsFactors = FALSE)
      colnames(info_zone) <- c("codgeo","libgeo","millesime_geo","libelle_sans_article","code_article")

      croisement <- res$Croisement
      source <- as.data.frame(do.call("cbind", croisement$JeuDonnees), stringsAsFactors = FALSE)
      colnames(source) <- c("jeu_donnees", "millesime_donnees", "lib_jeu_donnees","lib_source")

      source <- cbind(source, info_zone$millesime_geo)
      colnames(source)[colnames(source) =="info_zone$millesime_geo"] <- "millesime_geo"
      source$source <- paste0("Insee, ", source$lib_source, " ", source$millesime_donnees,
                              ", g\u00e9ographie au 01/01/", source$millesime_geo)

      variable <- res$Variable
      temp <- variable$Modalite
      info_modalite <- as.data.frame(cbind(variable$'@code',variable$Libelle), stringsAsFactors = FALSE)

      liste_code <- NULL
      if (nb_var > 1) {
        for (i in 1:length(temp)) {
          if (dim(as.data.frame(temp[[i]]))[1]>1){
            liste_code_temp <- data.frame(info_modalite[i,]$V1, info_modalite[i,]$V2, temp[[i]][,'@code'], temp[[i]][,'Libelle'],
                                          stringsAsFactors = FALSE)
            colnames(liste_code_temp) <- c("variable", "lib_varible", "modalite", "lib_modalite")
          } else {
            liste_code_temp <- data.frame(info_modalite[i,]$V1, info_modalite[i,]$V2,temp[[i]]['@code'],temp[[i]]['Libelle'],stringsAsFactors = FALSE)
            colnames(liste_code_temp) <- c("variable", "lib_varible", "modalite", "lib_modalite")
          }

          liste_code <- rbind(liste_code_temp, liste_code)
        }
      } else {
        if (dim(as.data.frame(temp))[1]>1){
          liste_code <- data.frame(cbind(info_modalite,temp[,'@code'], temp[,'Libelle']),
                                   stringsAsFactors = FALSE)
        } else {
          liste_code <- data.frame(cbind(info_modalite,temp['@code'], temp['Libelle']),
                                   stringsAsFactors = FALSE)
        }

        colnames(liste_code) <- c("variable", "lib_varible", "modalite", "lib_modalite")
      }

      cellule <- as.data.frame(res$Cellule)
      var <- cellule$Modalite

      var_tot <- NULL
      if (nb_var > 1) {
        for (i in (1:length(var))){
          var_tot <- rbind(var_tot, cbind(t(var[[i]][1])))
        }
        colnames(var_tot) <- c(t(var[[1]][2]))

        donnees <- cbind(cellule$Zone, cellule$Mesure, var_tot, cellule$Valeur)
        colnames(donnees) <- c("codgeo", "nivgeo", "mesure", "lib_mesure", c(t(var[[1]][2])), "valeur")

        donnees <- as.data.frame(donnees)

      } else {
        if (dim(as.data.frame(cellule))[1]>1){
          donnees <- do.call("cbind",cellule)
          donnees <- data.frame(donnees[,'Zone.@codgeo'], donnees[,'Zone.@nivgeo'],
                                donnees[,'Mesure.@code'], donnees[,'Mesure.$'],
                                donnees[,'Modalite.@code'], donnees[,'Valeur'], stringsAsFactors = FALSE)
          colnames(donnees) <- c("codgeo", "nivgeo", "mesure", "lib_mesure", var[[2]][2], "valeur")
        } else {
          var <- as.character(cellule[,'Modalite..variable'])
          donnees <- data.frame(cellule['Zone..codgeo'], cellule[,'Zone..nivgeo'],
                                cellule[,'Mesure..code'], cellule[,'Mesure..'],
                                cellule[,'Modalite..code'], cellule[,'Valeur'], stringsAsFactors = FALSE)
          colnames(donnees) <- c("codgeo", "nivgeo", "mesure", "lib_mesure", var, "valeur")
        }
      }

      if (!is.na(temporisation)){
        Sys.sleep(temporisation)
      }

      return(list(donnees=donnees, liste_code=liste_code, info_zone=info_zone, source = source))
    }
  }
}
