# Publier WoW Forever Rot sur CurseForge

Le jeton API **n’ouvre pas un projet**. Il sert uniquement à envoyer un zip **après** que la fiche existe (modération CurseForge).

## 1. Compte

1. https://www.curseforge.com — connexion Overwolf / CurseForge.
2. https://authors.curseforge.com — Author Portal.
3. Jeton : https://authors.curseforge.com/account/api-tokens  
   Ne le mets jamais dans git. Après un envoi, tu peux le révoquer et en recréer un.

## 2. Créer le projet (à la main, une fois)

https://authors.curseforge.com → **Create Project**

Valeurs dans `FIELDS.txt`. Logo : `logo-512.png`. Description : coller `DESCRIPTION.html` (WYSIWYG).

Attends l’approbation (souvent quelques heures). L’**ID numérique** est dans la colonne de droite de la fiche (« About Project » / Project ID). Ce n’est pas le slug `wow-forever-rot`.

## 3. Zip

```
python curseforge/pack.py
```

Sortie : `F:\Github\addons\wow\WoWForeverRot-1.5.8.zip`  
Racine du zip = dossier `WoWForeverRot` (sans numéro de version).

## 4. Envoyer le fichier

Dans l’onglet **Files** → **Upload file**, ou avec le jeton :

```
POST https://wow.curseforge.com/api/projects/PROJECT_ID/upload-file
Header: X-Api-Token
multipart: metadata (JSON) + file (le zip)
```

`gameVersions` = `[17053]` (nom CurseForge : **1.60.1**).

Forever n’est pas un client officiel. L’app CurseForge installe souvent dans Classic Era. Dis aux joueurs de dézipper dans `_classic_beta_`. La modération peut refuser un addon « serveur privé ».

## 5. Après acceptation

Dans les deux TOC :

```
## X-Curse-Project-ID: 123456
```

Remplace `123456` par l’ID réel.
