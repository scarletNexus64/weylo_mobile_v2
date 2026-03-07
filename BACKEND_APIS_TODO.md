# APIs Backend à implémenter pour les Confessions

Ce document liste les endpoints API qui doivent être ajoutés au backend pour supporter les nouvelles fonctionnalités de confessions.

## Base URL
`/api/v1/confessions`

## Endpoints à créer

### 1. Toggle Favorite (Enregistrer/Désépingler)
**Endpoint:** `POST /api/v1/confessions/{id}/favorite`

**Description:** Permet à un utilisateur d'ajouter ou retirer une confession de ses favoris.

**Requête:**
- Headers: `Authorization: Bearer {token}`
- Params: `{id}` - ID de la confession

**Réponse:**
```json
{
  "success": true,
  "message": "Confession ajoutée aux favoris",
  "is_favorited": true
}
```

---

### 2. Reveal Identity (Dévoiler l'auteur)
**Endpoint:** `POST /api/v1/confessions/{id}/reveal-identity`

**Description:** Permet à un utilisateur de voir l'identité réelle de l'auteur d'une confession anonyme.

**Requête:**
- Headers: `Authorization: Bearer {token}`
- Params: `{id}` - ID de la confession

**Réponse:**
```json
{
  "success": true,
  "author": {
    "id": 123,
    "name": "John Doe",
    "username": "johndoe",
    "avatar_url": "https://..."
  }
}
```

**Notes:**
- Cette action pourrait nécessiter une permission spéciale ou des crédits
- L'utilisateur ne devrait pas pouvoir dévoiler sa propre identité sur ses posts anonymes

---

### 3. Get Favorite Confessions
**Endpoint:** `GET /api/v1/confessions/favorites`

**Description:** Récupère la liste des confessions enregistrées par l'utilisateur.

**Requête:**
- Headers: `Authorization: Bearer {token}`
- Query Params:
  - `page` (optional, default: 1)
  - `per_page` (optional, default: 20)

**Réponse:**
```json
{
  "confessions": [
    {
      "id": 1,
      "content": "...",
      "type": "public",
      // ... autres champs de confession
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 95
  }
}
```

---

### 4. Update Confession
**Endpoint:** `PUT /api/v1/confessions/{id}`

**Description:** Permet à l'auteur de modifier sa confession.

**Requête:**
- Headers: `Authorization: Bearer {token}`
- Params: `{id}` - ID de la confession
- Body (multipart/form-data si média, sinon JSON):
```json
{
  "content": "Nouveau contenu...",
  "media_type": "image|video|none",
  "media": File (optional)
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Confession mise à jour avec succès",
  "confession": {
    "id": 1,
    "content": "Nouveau contenu...",
    // ... autres champs
  }
}
```

**Validation:**
- L'utilisateur doit être l'auteur de la confession
- Le contenu ne doit pas être vide si aucun média n'est fourni

---

### 5. Delete Confession (déjà existant?)
**Endpoint:** `DELETE /api/v1/confessions/{id}`

**Description:** Supprime une confession.

**Requête:**
- Headers: `Authorization: Bearer {token}`
- Params: `{id}` - ID de la confession

**Réponse:**
```json
{
  "success": true,
  "message": "Confession supprimée avec succès"
}
```

**Validation:**
- L'utilisateur doit être l'auteur de la confession

---

## Modèles de données

### Ajouter à la table `confessions`
Si ces champs n'existent pas encore:
- `favorited_by` (relation many-to-many avec `users`)

### Nouvelle table: `confession_favorites`
```sql
CREATE TABLE confession_favorites (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    confession_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (confession_id) REFERENCES confessions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_confession (user_id, confession_id)
);
```

### Nouvelle table: `confession_identity_reveals`
Pour tracker qui a dévoilé l'identité de qui:
```sql
CREATE TABLE confession_identity_reveals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT 'Utilisateur qui dévoile',
    confession_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (confession_id) REFERENCES confessions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_reveal (user_id, confession_id)
);
```

---

## Permissions et Sécurité

1. **Favoris:** Tout utilisateur authentifié peut ajouter/retirer des favoris
2. **Dévoiler identité:**
   - Option 1: Gratuit pour tous
   - Option 2: Nécessite des crédits/points
   - Option 3: Uniquement pour utilisateurs premium
3. **Modifier:** Uniquement l'auteur de la confession
4. **Supprimer:** Uniquement l'auteur de la confession

---

## Page Profile - Tab Enregistrés

La page profile devrait avoir un nouveau tab "Enregistrés" qui affiche les confessions favorites de l'utilisateur.

**Frontend déjà préparé:**
- Le service `ConfessionService.getFavoriteConfessions()` est déjà créé
- Il suffit d'ajouter un tab dans la page profile qui appelle cette méthode

---

## Récapitulatif des fichiers Flutter modifiés

1. ✅ `confession_service.dart` - Ajout des méthodes API
2. ✅ `confession_actions_bottom_sheet.dart` - Nouveau widget pour les actions
3. ✅ `edit_confession_view.dart` - Nouvelle page pour éditer
4. ✅ `feeds_view.dart` - Intégration du bottom sheet
5. ✅ `app_routes.dart` et `app_pages.dart` - Ajout de la route edit-confession

---

## Prochaines étapes

1. Implémenter les endpoints backend listés ci-dessus
2. Créer les migrations pour les nouvelles tables
3. Ajouter un tab "Enregistrés" dans la page profile
4. Tester toutes les fonctionnalités
