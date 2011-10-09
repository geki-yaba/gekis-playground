/* Based on gtktreestore.h
 * Copyright (C) 2000  Red Hat, Inc.,  Jonathan Blandford <jrb@redhat.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef __CM_TREE_STORE_H__
#define __CM_TREE_STORE_H__

#include <gdk/gdk.h>
#include <gtk/gtk.h>
#include <stdarg.h>


G_BEGIN_DECLS


#define CM_TYPE_TREE_STORE				(cm_tree_store_get_type ())
#define CM_TREE_STORE(obj)				(G_TYPE_CHECK_INSTANCE_CAST ((obj), CM_TYPE_TREE_STORE, CMTreeStore))
#define CM_TREE_STORE_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), CM_TYPE_TREE_STORE, CMTreeStoreClass))
#define CM_IS_TREE_STORE(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), CM_TYPE_TREE_STORE))
#define CM_IS_TREE_STORE_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), CM_TYPE_TREE_STORE))
#define CM_TREE_STORE_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), CM_TYPE_TREE_STORE, CMTreeStoreClass))

typedef struct _CMTreeStore        CMTreeStore;
typedef struct _CMTreeStoreClass   CMTreeStoreClass;
typedef struct _CMTreeStorePrivate CMTreeStorePrivate;

struct _CMTreeStore
{
  GObject parent;

  CMTreeStorePrivate *priv;
};

struct _CMTreeStoreClass
{
  GObjectClass parent_class;
};


GType        cm_tree_store_get_type         (void) G_GNUC_CONST;
CMTreeStore *cm_tree_store_new              (gint          n_columns,
                                             ...);
CMTreeStore *cm_tree_store_newv             (gint          n_columns,
                                             GType        *types);
void         cm_tree_store_set_column_types (CMTreeStore *tree_store,
                                             gint          n_columns,
                                             GType        *types);

/* NOTE: use gtk_tree_model_get to get values from a CMTreeStore */

void         cm_tree_store_set_value        (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             gint          column,
                                             GValue       *value);
void         cm_tree_store_set              (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             ...);
void         cm_tree_store_set_valuesv      (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             gint         *columns,
                                             GValue       *values,
                                             gint          n_values);
void         cm_tree_store_set_valist       (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             va_list       var_args);
gboolean     cm_tree_store_remove           (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter);
void         cm_tree_store_insert           (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *parent,
                                             gint          position);
void         cm_tree_store_insert_before    (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *parent,
                                             GtkTreeIter  *sibling);
void         cm_tree_store_insert_after     (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *parent,
                                             GtkTreeIter  *sibling);
void         cm_tree_store_insert_with_values (CMTreeStore *tree_store,
                                               GtkTreeIter  *iter,
                                               GtkTreeIter  *parent,
                                               gint          position,
                                               ...);
void         cm_tree_store_insert_with_valuesv (CMTreeStore *tree_store,
                                                GtkTreeIter  *iter,
                                                GtkTreeIter  *parent,
                                                gint          position,
                                                gint         *columns,
                                                GValue       *values,
                                                gint          n_values);
void         cm_tree_store_prepend          (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *parent);
void         cm_tree_store_append           (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *parent);
gboolean     cm_tree_store_is_ancestor      (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *descendant);
gint         cm_tree_store_iter_depth       (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter);
void         cm_tree_store_clear            (CMTreeStore *tree_store);
gboolean     cm_tree_store_iter_is_valid    (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter);
void         cm_tree_store_reorder          (CMTreeStore *tree_store,
                                             GtkTreeIter  *parent,
                                             gint         *new_order);
void         cm_tree_store_swap             (CMTreeStore *tree_store,
                                             GtkTreeIter  *a,
                                             GtkTreeIter  *b);
void         cm_tree_store_move_before      (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *position);
void         cm_tree_store_move_after       (CMTreeStore *tree_store,
                                             GtkTreeIter  *iter,
                                             GtkTreeIter  *position);


G_END_DECLS


#endif /* __CM_TREE_STORE_H__ */
