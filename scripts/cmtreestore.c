/* Based on gtktreestore.c
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

#include <gobject/gvaluecollector.h>
#include <gtk/gtk.h>
#include <string.h>

#include "cmtreestore.h"
#include "gtktreedatalist.h"


/**
 * SECTION:gtktreestore
 * @Short_description: A tree-like data structure that can be used with the GtkTreeView
 * @Title: CMTreeStore
 * @See_also: #GtkTreeModel
 *
 * The #CMTreeStore object is a list model for use with a #GtkTreeView
 * widget.  It implements the #GtkTreeModel interface, and consequentialy,
 * can use all of the methods available there.  It also implements the
 * #GtkTreeSortable interface so it can be sorted by the view.  Finally,
 * it also implements the tree <link linkend="gtktreednd">drag and
 * drop</link> interfaces.
 *
 * <refsect2 id="CMTreeStore-BUILDER-UI">
 * <title>CMTreeStore as GtkBuildable</title>
 * The CMTreeStore implementation of the #GtkBuildable interface allows
 * to specify the model columns with a &lt;columns&gt; element that may
 * contain multiple &lt;column&gt; elements, each specifying one model
 * column. The "type" attribute specifies the data type for the column.
 * <example>
 * <title>A UI Definition fragment for a tree store</title>
 * <programlisting><![CDATA[
 * <object class="CMTreeStore">
 *   <columns>
 *     <column type="gchararray"/>
 *     <column type="gchararray"/>
 *     <column type="gint"/>
 *   </columns>
 * </object>
 * ]]></programlisting>
 * </example>
 * </refsect2>
 */

struct _CMTreeStorePrivate
{
  gint stamp;
  gpointer root;
  gint n_columns;
  GType *column_headers;
  guint columns_dirty : 1;
  gboolean emit_signals;
};


#define VALID_ITER(iter, tree_store) ((iter) != NULL && (iter)->user_data != NULL && ((CMTreeStore*)(tree_store))->priv->stamp == (iter)->stamp)

static void         cm_tree_store_tree_model_init (GtkTreeModelIface *iface);
static void         cm_tree_store_drag_source_init(GtkTreeDragSourceIface *iface);
static void         cm_tree_store_drag_dest_init  (GtkTreeDragDestIface   *iface);
static void         cm_tree_store_buildable_init  (GtkBuildableIface      *iface);
static void         cm_tree_store_finalize        (GObject           *object);
static GtkTreeModelFlags cm_tree_store_get_flags  (GtkTreeModel      *tree_model);
static gint         cm_tree_store_get_n_columns   (GtkTreeModel      *tree_model);
static GType        cm_tree_store_get_column_type (GtkTreeModel      *tree_model,
						    gint               index);
static gboolean     cm_tree_store_get_iter        (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter,
						    GtkTreePath       *path);
static GtkTreePath *cm_tree_store_get_path        (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter);
static void         cm_tree_store_get_value       (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter,
						    gint               column,
						    GValue            *value);
static gboolean     cm_tree_store_iter_next       (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter);
static gboolean     cm_tree_store_iter_previous   (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter);
static gboolean     cm_tree_store_iter_children   (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter,
						    GtkTreeIter       *parent);
static gboolean     cm_tree_store_iter_has_child  (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter);
static gint         cm_tree_store_iter_n_children (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter);
static gboolean     cm_tree_store_iter_nth_child  (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter,
						    GtkTreeIter       *parent,
						    gint               n);
static gboolean     cm_tree_store_iter_parent     (GtkTreeModel      *tree_model,
						    GtkTreeIter       *iter,
						    GtkTreeIter       *child);


static void cm_tree_store_set_n_columns   (CMTreeStore *tree_store,
					    gint          n_columns);
static void cm_tree_store_set_column_type (CMTreeStore *tree_store,
					    gint          column,
					    GType         type);

static void cm_tree_store_increment_stamp (CMTreeStore  *tree_store);


/* DND interfaces */
static gboolean real_cm_tree_store_row_draggable   (GtkTreeDragSource *drag_source,
						   GtkTreePath       *path);
static gboolean cm_tree_store_drag_data_delete   (GtkTreeDragSource *drag_source,
						   GtkTreePath       *path);
static gboolean cm_tree_store_drag_data_get      (GtkTreeDragSource *drag_source,
						   GtkTreePath       *path,
						   GtkSelectionData  *selection_data);
static gboolean cm_tree_store_drag_data_received (GtkTreeDragDest   *drag_dest,
						   GtkTreePath       *dest,
						   GtkSelectionData  *selection_data);
static gboolean cm_tree_store_row_drop_possible  (GtkTreeDragDest   *drag_dest,
						   GtkTreePath       *dest_path,
						   GtkSelectionData  *selection_data);

/* buildable */

static gboolean cm_tree_store_buildable_custom_tag_start (GtkBuildable  *buildable,
							   GtkBuilder    *builder,
							   GObject       *child,
							   const gchar   *tagname,
							   GMarkupParser *parser,
							   gpointer      *data);
static void     cm_tree_store_buildable_custom_finished (GtkBuildable 	 *buildable,
							  GtkBuilder   	 *builder,
							  GObject      	 *child,
							  const gchar  	 *tagname,
							  gpointer     	  user_data);

static void     cm_tree_store_move                    (CMTreeStore           *tree_store,
                                                        GtkTreeIter            *iter,
                                                        GtkTreeIter            *position,
                                                        gboolean                before);


G_DEFINE_TYPE_WITH_CODE (CMTreeStore, cm_tree_store, G_TYPE_OBJECT,
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_TREE_MODEL,
						cm_tree_store_tree_model_init)
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_TREE_DRAG_SOURCE,
						cm_tree_store_drag_source_init)
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_TREE_DRAG_DEST,
						cm_tree_store_drag_dest_init)
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_BUILDABLE,
						cm_tree_store_buildable_init))

static void
cm_tree_store_class_init (CMTreeStoreClass *class)
{
  GObjectClass *object_class;

  object_class = (GObjectClass *) class;

  object_class->finalize = cm_tree_store_finalize;

  g_type_class_add_private (class, sizeof (CMTreeStorePrivate));
}

static void
cm_tree_store_tree_model_init (GtkTreeModelIface *iface)
{
  iface->get_flags = cm_tree_store_get_flags;
  iface->get_n_columns = cm_tree_store_get_n_columns;
  iface->get_column_type = cm_tree_store_get_column_type;
  iface->get_iter = cm_tree_store_get_iter;
  iface->get_path = cm_tree_store_get_path;
  iface->get_value = cm_tree_store_get_value;
  iface->iter_next = cm_tree_store_iter_next;
#if GTK_CHECK_VERSION(3, 0, 0)
  iface->iter_previous = cm_tree_store_iter_previous;
#endif
  iface->iter_children = cm_tree_store_iter_children;
  iface->iter_has_child = cm_tree_store_iter_has_child;
  iface->iter_n_children = cm_tree_store_iter_n_children;
  iface->iter_nth_child = cm_tree_store_iter_nth_child;
  iface->iter_parent = cm_tree_store_iter_parent;
}

static void
cm_tree_store_drag_source_init (GtkTreeDragSourceIface *iface)
{
  iface->row_draggable = real_cm_tree_store_row_draggable;
  iface->drag_data_delete = cm_tree_store_drag_data_delete;
  iface->drag_data_get = cm_tree_store_drag_data_get;
}

static void
cm_tree_store_drag_dest_init (GtkTreeDragDestIface *iface)
{
  iface->drag_data_received = cm_tree_store_drag_data_received;
  iface->row_drop_possible = cm_tree_store_row_drop_possible;
}

void
cm_tree_store_buildable_init (GtkBuildableIface *iface)
{
  iface->custom_tag_start = cm_tree_store_buildable_custom_tag_start;
  iface->custom_finished = cm_tree_store_buildable_custom_finished;
}

static void
cm_tree_store_init (CMTreeStore *tree_store)
{
  CMTreeStorePrivate *priv;

  priv = G_TYPE_INSTANCE_GET_PRIVATE (tree_store,
                                      CM_TYPE_TREE_STORE,
                                      CMTreeStorePrivate);
  tree_store->priv = priv;
  priv->root = cm_node_new (NULL);
  /* While the odds are against us getting 0...  */
  do
    {
      priv->stamp = g_random_int ();
    }
  while (priv->stamp == 0);

  priv->columns_dirty = FALSE;
  priv->emit_signals = TRUE;
}

/**
 * cm_tree_store_new:
 * @n_columns: number of columns in the tree store
 * @...: all #GType types for the columns, from first to last
 *
 * Creates a new tree store as with @n_columns columns each of the types passed
 * in.  Note that only types derived from standard GObject fundamental types
 * are supported.
 *
 * As an example, <literal>cm_tree_store_new (3, G_TYPE_INT, G_TYPE_STRING,
 * GDK_TYPE_PIXBUF);</literal> will create a new #CMTreeStore with three columns, of type
 * <type>int</type>, <type>string</type> and #GdkPixbuf respectively.
 *
 * Return value: a new #CMTreeStore
 **/
CMTreeStore *
cm_tree_store_new (gint n_columns,
			       ...)
{
  CMTreeStore *retval;
  va_list args;
  gint i;

  g_return_val_if_fail (n_columns > 0, NULL);

  retval = g_object_new (CM_TYPE_TREE_STORE, NULL);
  cm_tree_store_set_n_columns (retval, n_columns);

  va_start (args, n_columns);

  for (i = 0; i < n_columns; i++)
    {
      GType type = va_arg (args, GType);
      if (! _gtk_tree_data_list_check_type (type))
	{
	  g_warning ("%s: Invalid type %s\n", G_STRLOC, g_type_name (type));
	  g_object_unref (retval);
          va_end (args);
	  return NULL;
	}
      cm_tree_store_set_column_type (retval, i, type);
    }
  va_end (args);

  return retval;
}

/**
 * cm_tree_store_newv:
 * @n_columns: number of columns in the tree store
 * @types: (array length=n_columns): an array of #GType types for the columns, from first to last
 *
 * Non vararg creation function.  Used primarily by language bindings.
 *
 * Return value: (transfer full): a new #CMTreeStore
 * Rename to: cm_tree_store_new
 **/
CMTreeStore *
cm_tree_store_newv (gint   n_columns,
		     GType *types)
{
  CMTreeStore *retval;
  gint i;

  g_return_val_if_fail (n_columns > 0, NULL);

  retval = g_object_new (CM_TYPE_TREE_STORE, NULL);
  cm_tree_store_set_n_columns (retval, n_columns);

   for (i = 0; i < n_columns; i++)
    {
      if (! _gtk_tree_data_list_check_type (types[i]))
	{
	  g_warning ("%s: Invalid type %s\n", G_STRLOC, g_type_name (types[i]));
	  g_object_unref (retval);
	  return NULL;
	}
      cm_tree_store_set_column_type (retval, i, types[i]);
    }

  return retval;
}

/**
 * cm_tree_store_set_column_types:
 * @tree_store: A #CMTreeStore
 * @n_columns: Number of columns for the tree store
 * @types: (array length=n_columns): An array of #GType types, one for each column
 * 
 * This function is meant primarily for #GObjects that inherit from 
 * #CMTreeStore, and should only be used when constructing a new 
 * #CMTreeStore.  It will not function after a row has been added, 
 * or a method on the #GtkTreeModel interface is called.
 **/
void
cm_tree_store_set_column_types (CMTreeStore *tree_store,
				 gint          n_columns,
				 GType        *types)
{
  gint i;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (tree_store->priv->columns_dirty == 0);

  cm_tree_store_set_n_columns (tree_store, n_columns);
   for (i = 0; i < n_columns; i++)
    {
      if (! _gtk_tree_data_list_check_type (types[i]))
	{
	  g_warning ("%s: Invalid type %s\n", G_STRLOC, g_type_name (types[i]));
	  continue;
	}
      cm_tree_store_set_column_type (tree_store, i, types[i]);
    }
}

static void
cm_tree_store_set_n_columns (CMTreeStore *tree_store,
			      gint          n_columns)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  int i;

  if (priv->n_columns == n_columns)
    return;

  priv->column_headers = g_renew (GType, priv->column_headers, n_columns);
  for (i = priv->n_columns; i < n_columns; i++)
    priv->column_headers[i] = G_TYPE_INVALID;
  priv->n_columns = n_columns;
}

/**
 * cm_tree_store_set_column_type:
 * @tree_store: a #CMTreeStore
 * @column: column number
 * @type: type of the data to be stored in @column
 *
 * Supported types include: %G_TYPE_UINT, %G_TYPE_INT, %G_TYPE_UCHAR,
 * %G_TYPE_CHAR, %G_TYPE_BOOLEAN, %G_TYPE_POINTER, %G_TYPE_FLOAT,
 * %G_TYPE_DOUBLE, %G_TYPE_STRING, %G_TYPE_OBJECT, and %G_TYPE_BOXED, along with
 * subclasses of those types such as %GDK_TYPE_PIXBUF.
 *
 **/
static void
cm_tree_store_set_column_type (CMTreeStore *tree_store,
				gint          column,
				GType         type)
{
  CMTreeStorePrivate *priv = tree_store->priv;

  if (!_gtk_tree_data_list_check_type (type))
    {
      g_warning ("%s: Invalid type %s\n", G_STRLOC, g_type_name (type));
      return;
    }
  priv->column_headers[column] = type;
}

static void
node_data_free (gpointer key,
          gpointer value,
          gpointer data)
{
  CMNode *node = CM_NODE (value);

  if (node->data)
    _gtk_tree_data_list_free (node->data, (GType*)data);
  node->data = NULL;

  if (node->children)
    g_hash_table_foreach (node->children, node_data_free, data);
}

static void
cm_tree_store_finalize (GObject *object)
{
  CMTreeStore *tree_store = CM_TREE_STORE (object);
  CMTreeStorePrivate *priv = tree_store->priv;

  g_hash_table_foreach (CM_NODE (priv->root)->children, node_data_free,
    priv->column_headers);
  cm_node_destroy (priv->root);
  g_free (priv->column_headers);

  /* must chain up */
  G_OBJECT_CLASS (cm_tree_store_parent_class)->finalize (object);
}

/* fulfill the GtkTreeModel requirements */
/* NOTE: CMTreeStore::root is a CMNode, that acts as the parent node.  However,
 * it is not visible to the tree or to the user., and the path "0" refers to the
 * first child of CMTreeStore::root.
 */
static GtkTreeModelFlags
cm_tree_store_get_flags (GtkTreeModel *tree_model)
{
  return GTK_TREE_MODEL_ITERS_PERSIST;
}

static gint
cm_tree_store_get_n_columns (GtkTreeModel *tree_model)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;

  priv->columns_dirty = TRUE;

  return priv->n_columns;
}

static GType
cm_tree_store_get_column_type (GtkTreeModel *tree_model,
				gint          index)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;

  g_return_val_if_fail (index < priv->n_columns, G_TYPE_INVALID);

  priv->columns_dirty = TRUE;

  return priv->column_headers[index];
}

static gboolean
cm_tree_store_get_iter (GtkTreeModel *tree_model,
			 GtkTreeIter  *iter,
			 GtkTreePath  *path)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreeIter parent;
  gint *indices;
  gint depth, i;

  priv->columns_dirty = TRUE;

  indices = gtk_tree_path_get_indices (path);
  depth = gtk_tree_path_get_depth (path);

  g_return_val_if_fail (depth > 0, FALSE);

  parent.stamp = priv->stamp;
  parent.user_data = priv->root;

  if (!cm_tree_store_iter_nth_child (tree_model, iter, &parent, indices[0]))
    {
      iter->stamp = 0;
      return FALSE;
    }

  for (i = 1; i < depth; i++)
    {
      parent = *iter;
      if (!cm_tree_store_iter_nth_child (tree_model, iter, &parent, indices[i]))
        {
          iter->stamp = 0;
          return FALSE;
        }
    }

  return TRUE;
}

static GtkTreePath *
cm_tree_store_get_path (GtkTreeModel *tree_model,
			 GtkTreeIter  *iter)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNodeForeach find;
  CMNode *node, *tmp_node;
  GtkTreePath *retval;
  gint i = 0;

  g_return_val_if_fail (iter->user_data != NULL, NULL);
  g_return_val_if_fail (iter->stamp == priv->stamp, NULL);

  if (CM_NODE (iter->user_data)->parent == NULL &&
      CM_NODE (iter->user_data) == priv->root)
    return gtk_tree_path_new ();
  g_assert (CM_NODE (iter->user_data)->parent != NULL);

  if (CM_NODE (iter->user_data)->parent == CM_NODE (priv->root))
    {
      retval = gtk_tree_path_new ();
      node = CM_NODE (priv->root);
      tmp_node = CM_NODE (g_hash_table_lookup (node->children,
          GINT_TO_POINTER(0)));
    }
  else
    {
      GtkTreeIter tmp_iter = *iter;

      tmp_iter.user_data = CM_NODE (iter->user_data)->parent;

      retval = cm_tree_store_get_path (tree_model, &tmp_iter);
      node = CM_NODE (iter->user_data)->parent;
      tmp_node = CM_NODE (g_hash_table_lookup (node->children,
          GINT_TO_POINTER(0)));
    }

  if (retval == NULL)
    return NULL;

  if (tmp_node == NULL)
    {
      gtk_tree_path_free (retval);
      return NULL;
    }

  find.data = iter->user_data;

  tmp_node = g_hash_table_find (node->children, cm_node_find_child_func, &find);
  if (tmp_node)
    {
      i = GPOINTER_TO_INT (find.data);
    }
  else
    {
      /* We couldn't find node, meaning it's prolly not ours */
      /* Perhaps I should do a g_return_if_fail here. */
      gtk_tree_path_free (retval);
      return NULL;
    }

  gtk_tree_path_append_index (retval, i);

  return retval;
}


static void
cm_tree_store_get_value (GtkTreeModel *tree_model,
			  GtkTreeIter  *iter,
			  gint          column,
			  GValue       *value)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreeDataList *list;
  gint tmp_column = column;

  g_return_if_fail (column < priv->n_columns);
  g_return_if_fail (VALID_ITER (iter, tree_store));

  list = CM_NODE (iter->user_data)->data;

  while (tmp_column-- > 0 && list)
    list = list->next;

  if (list)
    {
      _gtk_tree_data_list_node_to_value (list,
					 priv->column_headers[column],
					 value);
    }
  else
    {
      /* We want to return an initialized but empty (default) value */
      g_value_init (value, priv->column_headers[column]);
    }
}

static gboolean
cm_tree_store_iter_next (GtkTreeModel  *tree_model,
			  GtkTreeIter   *iter)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNode *parent;
  CMNode *next = NULL;
  gint i;

  g_return_val_if_fail (iter->user_data != NULL, FALSE);
  g_return_val_if_fail (iter->stamp == priv->stamp, FALSE);

  parent = CM_NODE (iter->user_data)->parent;
  if (!parent)
    parent = priv->root;

  i = GPOINTER_TO_INT (iter->user_data2) + 1;
  if (parent->children)
    next = CM_NODE (g_hash_table_lookup (parent->children, GINT_TO_POINTER (i)));
  if (next == NULL)
    {
      iter->stamp = 0;
      return FALSE;
    }

  iter->user_data = next;
  iter->user_data2 = GINT_TO_POINTER (i);

  return TRUE;
}

static gboolean
cm_tree_store_iter_previous (GtkTreeModel *tree_model,
                              GtkTreeIter  *iter)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNode *parent;
  CMNode *prev = NULL;
  gint i;

  g_return_val_if_fail (iter->user_data != NULL, FALSE);
  g_return_val_if_fail (iter->stamp == priv->stamp, FALSE);

  parent = CM_NODE (iter->user_data)->parent;
  if (!parent)
    parent = priv->root;

  i = GPOINTER_TO_INT (iter->user_data2) - 1;
  if (parent->children)
    prev = CM_NODE (g_hash_table_lookup (parent->children, GINT_TO_POINTER (i)));
  if (prev == NULL)
    {
      iter->stamp = 0;
      return FALSE;
    }

  iter->user_data = prev;
  iter->user_data2 = GINT_TO_POINTER (i);

  return TRUE;
}

static gboolean
cm_tree_store_iter_children (GtkTreeModel *tree_model,
			      GtkTreeIter  *iter,
			      GtkTreeIter  *parent)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  GHashTable *children;

  if (parent)
    g_return_val_if_fail (VALID_ITER (parent, tree_store), FALSE);

  if (parent)
    children = CM_NODE (parent->user_data)->children;
  else
    children = CM_NODE (priv->root)->children;

  if (children)
    {
      iter->stamp = priv->stamp;
      iter->user_data = CM_NODE (g_hash_table_lookup (children,
          GINT_TO_POINTER (0)));
      iter->user_data2 = GINT_TO_POINTER (0);
      return TRUE;
    }
  else
    {
      iter->stamp = 0;
      return FALSE;
    }
}

static gboolean
cm_tree_store_iter_has_child (GtkTreeModel *tree_model,
			       GtkTreeIter  *iter)
{
  g_return_val_if_fail (iter->user_data != NULL, FALSE);
  g_return_val_if_fail (VALID_ITER (iter, tree_model), FALSE);

  return CM_NODE (iter->user_data)->children != NULL;
}

static gint
cm_tree_store_iter_n_children (GtkTreeModel *tree_model,
				GtkTreeIter  *iter)
{
  GHashTable *children;

  g_return_val_if_fail (iter == NULL || iter->user_data != NULL, 0);

  if (iter == NULL)
    children = CM_NODE (CM_TREE_STORE (tree_model)->priv->root)->children;
  else
    children = CM_NODE (iter->user_data)->children;

  return (gint)g_hash_table_size (children);
}

static gboolean
cm_tree_store_iter_nth_child (GtkTreeModel *tree_model,
			       GtkTreeIter  *iter,
			       GtkTreeIter  *parent,
			       gint          n)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNode *parent_node;
  CMNode *child;

  g_return_val_if_fail (parent == NULL || parent->user_data != NULL, FALSE);

  if (parent == NULL)
    parent_node = priv->root;
  else
    parent_node = parent->user_data;

  child = cm_node_nth_child (parent_node, n);

  if (child)
    {
      iter->stamp = priv->stamp;
      iter->user_data = child;
      iter->user_data2 = GINT_TO_POINTER (n);
      return TRUE;
    }
  else
    {
      iter->stamp = 0;
      return FALSE;
    }
}

static gboolean
cm_tree_store_iter_parent (GtkTreeModel *tree_model,
			    GtkTreeIter  *iter,
			    GtkTreeIter  *child)
{
  CMTreeStore *tree_store = (CMTreeStore *) tree_model;
  CMTreeStorePrivate *priv = tree_store->priv;
  GHashTable *children = NULL;
  CMNode *parent;

  g_return_val_if_fail (iter != NULL, FALSE);
  g_return_val_if_fail (VALID_ITER (child, tree_store), FALSE);

  if ((parent = CM_NODE (child->user_data)->parent)
   && (parent = parent->parent))
    children = parent->children;

  if (children)
    {
      iter->stamp = priv->stamp;
      iter->user_data = CM_NODE (g_hash_table_lookup (children,
          GINT_TO_POINTER (0)));
      iter->user_data2 = GINT_TO_POINTER (0);
      return TRUE;
    }
  else
    {
      iter->stamp = 0;
      return FALSE;
    }
}


/* Does not emit a signal */
static gboolean
cm_tree_store_real_set_value (CMTreeStore *tree_store,
			       GtkTreeIter  *iter,
			       gint          column,
			       GValue       *value)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreeDataList *list;
  GtkTreeDataList *prev;
  gint old_column = column;
  GValue real_value = { 0, };
  gboolean converted = FALSE;
  gboolean retval = FALSE;

  if (! g_type_is_a (G_VALUE_TYPE (value), priv->column_headers[column]))
    {
      if (! (g_value_type_compatible (G_VALUE_TYPE (value), priv->column_headers[column]) &&
	     g_value_type_compatible (priv->column_headers[column], G_VALUE_TYPE (value))))
	{
	  g_warning ("%s: Unable to convert from %s to %s\n",
		     G_STRLOC,
		     g_type_name (G_VALUE_TYPE (value)),
		     g_type_name (priv->column_headers[column]));
	  return retval;
	}
      if (!g_value_transform (value, &real_value))
	{
	  g_warning ("%s: Unable to make conversion from %s to %s\n",
		     G_STRLOC,
		     g_type_name (G_VALUE_TYPE (value)),
		     g_type_name (priv->column_headers[column]));
	  g_value_unset (&real_value);
	  return retval;
	}
      converted = TRUE;
    }

  prev = list = CM_NODE (iter->user_data)->data;

  while (list != NULL)
    {
      if (column == 0)
	{
	  if (converted)
	    _gtk_tree_data_list_value_to_node (list, &real_value);
	  else
	    _gtk_tree_data_list_value_to_node (list, value);
	  retval = TRUE;
	  if (converted)
	    g_value_unset (&real_value);
	  return retval;
	}

      column--;
      prev = list;
      list = list->next;
    }

  if (CM_NODE (iter->user_data)->data == NULL)
    {
      CM_NODE (iter->user_data)->data = list = _gtk_tree_data_list_alloc ();
      list->next = NULL;
    }
  else
    {
      list = prev->next = _gtk_tree_data_list_alloc ();
      list->next = NULL;
    }

  while (column != 0)
    {
      list->next = _gtk_tree_data_list_alloc ();
      list = list->next;
      list->next = NULL;
      column --;
    }

  if (converted)
    _gtk_tree_data_list_value_to_node (list, &real_value);
  else
    _gtk_tree_data_list_value_to_node (list, value);
  
  retval = TRUE;
  if (converted)
    g_value_unset (&real_value);

  return retval;
}

/**
 * cm_tree_store_set_value:
 * @tree_store: a #CMTreeStore
 * @iter: A valid #GtkTreeIter for the row being modified
 * @column: column number to modify
 * @value: new value for the cell
 *
 * Sets the data in the cell specified by @iter and @column.
 * The type of @value must be convertible to the type of the
 * column.
 *
 **/
void
cm_tree_store_set_value (CMTreeStore *tree_store,
			  GtkTreeIter  *iter,
			  gint          column,
			  GValue       *value)
{
  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (VALID_ITER (iter, tree_store));
  g_return_if_fail (column >= 0 && column < tree_store->priv->n_columns);
  g_return_if_fail (G_IS_VALUE (value));

  if (cm_tree_store_real_set_value (tree_store, iter, column, value)
    && tree_store->priv->emit_signals)
    {
      GtkTreePath *path;

      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_model_row_changed (GTK_TREE_MODEL (tree_store), path, iter);
      gtk_tree_path_free (path);
    }
}

static void
cm_tree_store_set_vector_internal (CMTreeStore *tree_store,
				    GtkTreeIter  *iter,
				    gboolean     *emit_signal,
				    gint         *columns,
				    GValue       *values,
				    gint          n_values)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  gint i;

  for (i = 0; i < n_values; i++)
    {
      *emit_signal = cm_tree_store_real_set_value (tree_store, iter,
						    columns[i], &values[i]) || *emit_signal;
    }
}

static void
cm_tree_store_set_valist_internal (CMTreeStore *tree_store,
                                    GtkTreeIter  *iter,
                                    gboolean     *emit_signal,
                                    va_list       var_args)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  gint column;

  column = va_arg (var_args, gint);

  while (column != -1)
    {
      GValue value = { 0, };
      gchar *error = NULL;

      if (column < 0 || column >= priv->n_columns)
	{
	  g_warning ("%s: Invalid column number %d added to iter (remember to end your list of columns with a -1)", G_STRLOC, column);
	  break;
	}

      G_VALUE_COLLECT_INIT (&value, priv->column_headers[column],
                            var_args, 0, &error);
      if (error)
	{
	  g_warning ("%s: %s", G_STRLOC, error);
	  g_free (error);

 	  /* we purposely leak the value here, it might not be
	   * in a sane state if an error condition occoured
	   */
	  break;
	}

      *emit_signal = cm_tree_store_real_set_value (tree_store,
						    iter,
						    column,
						    &value) || *emit_signal;

      g_value_unset (&value);

      column = va_arg (var_args, gint);
    }
}

/**
 * cm_tree_store_set_valuesv:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter for the row being modified
 * @columns: (array length=n_values): an array of column numbers
 * @values: (array length=n_values): an array of GValues
 * @n_values: the length of the @columns and @values arrays
 *
 * A variant of cm_tree_store_set_valist() which takes
 * the columns and values as two arrays, instead of varargs.  This
 * function is mainly intended for language bindings or in case
 * the number of columns to change is not known until run-time.
 *
 * Since: 2.12
 * Rename to: cm_tree_store_set
 **/
void
cm_tree_store_set_valuesv (CMTreeStore *tree_store,
			    GtkTreeIter  *iter,
			    gint         *columns,
			    GValue       *values,
			    gint          n_values)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  gboolean emit_signal = FALSE;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (VALID_ITER (iter, tree_store));

  cm_tree_store_set_vector_internal (tree_store, iter,
				      &emit_signal,
				      columns, values, n_values);

  if (emit_signal && priv->emit_signals)
    {
      GtkTreePath *path;

      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_model_row_changed (GTK_TREE_MODEL (tree_store), path, iter);
      gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_set_valist:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter for the row being modified
 * @var_args: <type>va_list</type> of column/value pairs
 *
 * See cm_tree_store_set(); this version takes a <type>va_list</type> for
 * use by language bindings.
 *
 **/
void
cm_tree_store_set_valist (CMTreeStore *tree_store,
                           GtkTreeIter  *iter,
                           va_list       var_args)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  gboolean emit_signal = FALSE;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (VALID_ITER (iter, tree_store));

  cm_tree_store_set_valist_internal (tree_store, iter,
				      &emit_signal,
				      var_args);

  if (emit_signal && priv->emit_signals)
    {
      GtkTreePath *path;

      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_model_row_changed (GTK_TREE_MODEL (tree_store), path, iter);
      gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_set:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter for the row being modified
 * @...: pairs of column number and value, terminated with -1
 *
 * Sets the value of one or more cells in the row referenced by @iter.
 * The variable argument list should contain integer column numbers,
 * each column number followed by the value to be set.
 * The list is terminated by a -1. For example, to set column 0 with type
 * %G_TYPE_STRING to "Foo", you would write
 * <literal>cm_tree_store_set (store, iter, 0, "Foo", -1)</literal>.
 *
 * The value will be referenced by the store if it is a %G_TYPE_OBJECT, and it
 * will be copied if it is a %G_TYPE_STRING or %G_TYPE_BOXED.
 **/
void
cm_tree_store_set (CMTreeStore *tree_store,
		    GtkTreeIter  *iter,
		    ...)
{
  va_list var_args;

  va_start (var_args, iter);
  cm_tree_store_set_valist (tree_store, iter, var_args);
  va_end (var_args);
}

/**
 * cm_tree_store_remove:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter
 * 
 * Removes @iter from @tree_store.  After being removed, @iter is set to the
 * next valid row at that level, or invalidated if it previously pointed to the
 * last one.
 *
 * Return value: %TRUE if @iter is still valid, %FALSE if not.
 **/
gboolean
cm_tree_store_remove (CMTreeStore *tree_store,
		       GtkTreeIter  *iter)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  GtkTreeIter new_iter = {0,};
  GHashTable *hash;
  CMNode *parent;
  CMNode *next_node;
  guint length;
  gint i, j;

  g_return_val_if_fail (CM_IS_TREE_STORE (tree_store), FALSE);
  g_return_val_if_fail (VALID_ITER (iter, tree_store), FALSE);

  parent = CM_NODE (iter->user_data)->parent;

  g_assert (parent != NULL);

  hash = parent->children;
  length = g_hash_table_size (hash);

  /* o well, got a better idea? please ... */
  j = GPOINTER_TO_INT (iter->user_data2);
  g_hash_table_steal (hash, iter->user_data2);
  for (i = j + 1; i < length; i++)
    {
      gpointer data = g_hash_table_lookup (hash, GINT_TO_POINTER (i));
      g_hash_table_steal (hash, GINT_TO_POINTER (i));
      g_hash_table_insert (hash, GINT_TO_POINTER (i - 1), data);
    }

  if (j < 0)
    next_node = NULL;
  else
    next_node = CM_NODE (g_hash_table_lookup (parent->children, GINT_TO_POINTER (j)));

  if (CM_NODE (iter->user_data)->data)
    node_data_free(GINT_TO_POINTER (0), iter->user_data, priv->column_headers);

  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  cm_node_destroy (CM_NODE (iter->user_data));

  gtk_tree_model_row_deleted (GTK_TREE_MODEL (tree_store), path);

  if (priv->emit_signals)
    {
  if (parent != CM_NODE (priv->root))
    {
      /* child_toggled */
      if (parent->children == NULL)
	{
	  gtk_tree_path_up (path);

	  new_iter.stamp = priv->stamp;
	  new_iter.user_data = parent;
	  gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, &new_iter);
	}
    }
  gtk_tree_path_free (path);
    }

  /* revalidate iter */
  if (next_node != NULL)
    {
      iter->stamp = priv->stamp;
      iter->user_data = next_node;
      iter->user_data2 = GINT_TO_POINTER (j);
      return TRUE;
    }
  else
    {
      iter->stamp = 0;
      iter->user_data = NULL;
    }

  return FALSE;
}

/**
 * cm_tree_store_insert:
 * @tree_store: A #CMTreeStore
 * @iter: (out): An unset #GtkTreeIter to set to the new row
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * @position: position to insert the new row
 *
 * Creates a new row at @position.  If parent is non-%NULL, then the row will be
 * made a child of @parent.  Otherwise, the row will be created at the toplevel.
 * If @position is larger than the number of rows at that level, then the new
 * row will be inserted to the end of the list.  @iter will be changed to point
 * to this new row.  The row will be empty after this function is called.  To
 * fill in values, you need to call cm_tree_store_set() or
 * cm_tree_store_set_value().
 *
 **/
void
cm_tree_store_insert (CMTreeStore *tree_store,
		       GtkTreeIter  *iter,
		       GtkTreeIter  *parent,
		       gint          position)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  CMNode *parent_node;
  CMNode *new_node;
  guint i = 0;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (iter != NULL);
  if (parent)
    g_return_if_fail (VALID_ITER (parent, tree_store));

  if (parent)
    parent_node = parent->user_data;
  else
    parent_node = priv->root;

  priv->columns_dirty = TRUE;

  new_node = cm_node_new (NULL);
  if (parent_node->children)
    i = g_hash_table_size (parent_node->children);

  iter->stamp = priv->stamp;
  iter->user_data = new_node;
  iter->user_data2 = GUINT_TO_POINTER (i);
  cm_node_append (parent_node, new_node);

  if (priv->emit_signals)
    {
  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

  if (parent_node != priv->root)
    {
      if (i == 0)
        {
          gtk_tree_path_up (path);
          gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, parent);
        }
    }

  gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_insert_before:
 * @tree_store: A #CMTreeStore
 * @iter: (out): An unset #GtkTreeIter to set to the new row
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * @sibling: (allow-none): A valid #GtkTreeIter, or %NULL
 *
 * Inserts a new row before @sibling.  If @sibling is %NULL, then the row will
 * be appended to @parent 's children.  If @parent and @sibling are %NULL, then
 * the row will be appended to the toplevel.  If both @sibling and @parent are
 * set, then @parent must be the parent of @sibling.  When @sibling is set,
 * @parent is optional.
 *
 * @iter will be changed to point to this new row.  The row will be empty after
 * this function is called.  To fill in values, you need to call
 * cm_tree_store_set() or cm_tree_store_set_value().
 *
 **/
void
cm_tree_store_insert_before (CMTreeStore *tree_store,
			      GtkTreeIter  *iter,
			      GtkTreeIter  *parent,
			      GtkTreeIter  *sibling)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  CMNode *parent_node = NULL;
  CMNode *new_node;
  guint i = 0;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (iter != NULL);
  if (parent != NULL)
    g_return_if_fail (VALID_ITER (parent, tree_store));
  if (sibling != NULL)
    g_return_if_fail (VALID_ITER (sibling, tree_store));

  if (parent == NULL && sibling == NULL)
    parent_node = priv->root;
  else if (parent == NULL)
    parent_node = CM_NODE (sibling->user_data)->parent;
  else if (sibling == NULL)
    parent_node = CM_NODE (parent->user_data);
  else
    {
      g_return_if_fail (CM_NODE (sibling->user_data)->parent == CM_NODE (parent->user_data));
      parent_node = CM_NODE (parent->user_data);
    }

  priv->columns_dirty = TRUE;

  new_node = cm_node_new (NULL);
  if (parent_node->children)
    i = g_hash_table_size (parent_node->children);

  iter->stamp = priv->stamp;
  iter->user_data = new_node;
  iter->user_data2 = GUINT_TO_POINTER (i);
  cm_node_append (parent_node, new_node);

  if (priv->emit_signals)
    {
  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

  if (parent_node != priv->root)
    {
      if (i == 0)
        {
          GtkTreeIter parent_iter;

          parent_iter.stamp = priv->stamp;
          parent_iter.user_data = parent_node;

          gtk_tree_path_up (path);
          gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, &parent_iter);
        }
    }

  gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_insert_after:
 * @tree_store: A #CMTreeStore
 * @iter: (out): An unset #GtkTreeIter to set to the new row
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * @sibling: (allow-none): A valid #GtkTreeIter, or %NULL
 *
 * Inserts a new row after @sibling.  If @sibling is %NULL, then the row will be
 * prepended to @parent 's children.  If @parent and @sibling are %NULL, then
 * the row will be prepended to the toplevel.  If both @sibling and @parent are
 * set, then @parent must be the parent of @sibling.  When @sibling is set,
 * @parent is optional.
 *
 * @iter will be changed to point to this new row.  The row will be empty after
 * this function is called.  To fill in values, you need to call
 * cm_tree_store_set() or cm_tree_store_set_value().
 *
 **/
void
cm_tree_store_insert_after (CMTreeStore *tree_store,
			     GtkTreeIter  *iter,
			     GtkTreeIter  *parent,
			     GtkTreeIter  *sibling)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  CMNode *parent_node;
  CMNode *new_node;
  guint i = 0;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (iter != NULL);
  if (parent != NULL)
    g_return_if_fail (VALID_ITER (parent, tree_store));
  if (sibling != NULL)
    g_return_if_fail (VALID_ITER (sibling, tree_store));

  if (parent == NULL && sibling == NULL)
    parent_node = priv->root;
  else if (parent == NULL)
    parent_node = CM_NODE (sibling->user_data)->parent;
  else if (sibling == NULL)
    parent_node = CM_NODE (parent->user_data);
  else
    {
      g_return_if_fail (CM_NODE (sibling->user_data)->parent ==
                        CM_NODE (parent->user_data));
      parent_node = CM_NODE (parent->user_data);
    }

  priv->columns_dirty = TRUE;

  new_node = cm_node_new (NULL);
  if (parent_node->children)
    i = g_hash_table_size (parent_node->children);

  iter->stamp = priv->stamp;
  iter->user_data = new_node;
  iter->user_data2 = GUINT_TO_POINTER (i);
  cm_node_append (parent_node, new_node);

  if (priv->emit_signals)
    {
  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

  if (parent_node != priv->root)
    {
      if (i == 0)
        {
          GtkTreeIter parent_iter;

          parent_iter.stamp = priv->stamp;
          parent_iter.user_data = parent_node;

          gtk_tree_path_up (path);
          gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, &parent_iter);
        }
    }

  gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_insert_with_values:
 * @tree_store: A #CMTreeStore
 * @iter: (out) (allow-none): An unset #GtkTreeIter to set the new row, or %NULL.
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * @position: position to insert the new row
 * @...: pairs of column number and value, terminated with -1
 *
 * Creates a new row at @position. @iter will be changed to point to this
 * new row. If @position is larger than the number of rows on the list, then
 * the new row will be appended to the list. The row will be filled with
 * the values given to this function.
 *
 * Calling
 * <literal>cm_tree_store_insert_with_values (tree_store, iter, position, ...)</literal>
 * has the same effect as calling
 * |[
 * cm_tree_store_insert (tree_store, iter, position);
 * cm_tree_store_set (tree_store, iter, ...);
 * ]|
 * with the different that the former will only emit a row_inserted signal,
 * while the latter will emit row_inserted, row_changed and if the tree store
 * is sorted, rows_reordered.  Since emitting the rows_reordered signal
 * repeatedly can affect the performance of the program,
 * cm_tree_store_insert_with_values() should generally be preferred when
 * inserting rows in a sorted tree store.
 *
 * Since: 2.10
 */
void
cm_tree_store_insert_with_values (CMTreeStore *tree_store,
				   GtkTreeIter  *iter,
				   GtkTreeIter  *parent,
				   gint          position,
				   ...)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  CMNode *parent_node;
  CMNode *new_node;
  GtkTreeIter tmp_iter;
  va_list var_args;
  gboolean changed = FALSE;
  guint i = 0;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));

  if (!iter)
    iter = &tmp_iter;

  if (parent)
    g_return_if_fail (VALID_ITER (parent, tree_store));

  if (parent)
    parent_node = parent->user_data;
  else
    parent_node = priv->root;

  priv->columns_dirty = TRUE;

  new_node = cm_node_new (NULL);
  if (parent_node->children)
    i = g_hash_table_size (parent_node->children);

  iter->stamp = priv->stamp;
  iter->user_data = new_node;
  iter->user_data2 = GUINT_TO_POINTER (i);
  cm_node_append (parent_node, new_node);

  va_start (var_args, position);
  cm_tree_store_set_valist_internal (tree_store, iter,
				      &changed,
				      var_args);
  va_end (var_args);

  if (priv->emit_signals)
    {
  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

  if (parent_node != priv->root)
    {
      if (i == 0)
        {
	  gtk_tree_path_up (path);
	  gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, parent);
	}
    }

  gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_insert_with_valuesv:
 * @tree_store: A #CMTreeStore
 * @iter: (out) (allow-none): An unset #GtkTreeIter to set the new row, or %NULL.
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * @position: position to insert the new row
 * @columns: (array length=n_values): an array of column numbers
 * @values: (array length=n_values): an array of GValues
 * @n_values: the length of the @columns and @values arrays
 *
 * A variant of cm_tree_store_insert_with_values() which takes
 * the columns and values as two arrays, instead of varargs.  This
 * function is mainly intended for language bindings.
 *
 * Since: 2.10
 * Rename to: cm_tree_store_insert_with_values
 */
void
cm_tree_store_insert_with_valuesv (CMTreeStore *tree_store,
				    GtkTreeIter  *iter,
				    GtkTreeIter  *parent,
				    gint          position,
				    gint         *columns,
				    GValue       *values,
				    gint          n_values)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  GtkTreePath *path;
  CMNode *parent_node;
  CMNode *new_node;
  GtkTreeIter tmp_iter;
  gboolean changed = FALSE;
  guint i = 0;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));

  if (!iter)
    iter = &tmp_iter;

  if (parent)
    g_return_if_fail (VALID_ITER (parent, tree_store));

  if (parent)
    parent_node = parent->user_data;
  else
    parent_node = priv->root;

  priv->columns_dirty = TRUE;

  new_node = cm_node_new (NULL);
  if (parent_node->children)
    i = g_hash_table_size (parent_node->children);

  iter->stamp = priv->stamp;
  iter->user_data = new_node;
  iter->user_data2 = GUINT_TO_POINTER (i);
  cm_node_append (parent_node, new_node);

  cm_tree_store_set_vector_internal (tree_store, iter,
				      &changed,
				      columns, values, n_values);

  if (priv->emit_signals)
    {
  path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
  gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

  if (parent_node != priv->root)
    {
      if (i == 0)
        {
	  gtk_tree_path_up (path);
	  gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, parent);
	}
    }

  gtk_tree_path_free (path);
    }
}

/**
 * cm_tree_store_prepend:
 * @tree_store: A #CMTreeStore
 * @iter: (out): An unset #GtkTreeIter to set to the prepended row
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * 
 * Prepends a new row to @tree_store.  If @parent is non-%NULL, then it will prepend
 * the new row before the first child of @parent, otherwise it will prepend a row
 * to the top level.  @iter will be changed to point to this new row.  The row
 * will be empty after this function is called.  To fill in values, you need to
 * call cm_tree_store_set() or cm_tree_store_set_value().
 **/
void
cm_tree_store_prepend (CMTreeStore *tree_store,
			GtkTreeIter  *iter,
			GtkTreeIter  *parent)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNode *parent_node, *new_node;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (iter != NULL);
  if (parent != NULL)
    g_return_if_fail (VALID_ITER (parent, tree_store));

  priv->columns_dirty = TRUE;

  if (parent == NULL)
    parent_node = priv->root;
  else
    parent_node = parent->user_data;

  if (parent_node->children == NULL)
    {
      GtkTreePath *path;

      new_node = cm_node_new (NULL);
      
      iter->stamp = priv->stamp;
      iter->user_data = new_node;
      iter->user_data2 = GINT_TO_POINTER (0);
      cm_node_append (parent_node, new_node);

  if (priv->emit_signals)
    {
      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

      if (parent_node != priv->root)
	{
	  gtk_tree_path_up (path);
	  gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, parent);
	}
      gtk_tree_path_free (path);
    }
    }
  else
    {
      cm_tree_store_insert_after (tree_store, iter, parent, NULL);
    }
}

/**
 * cm_tree_store_append:
 * @tree_store: A #CMTreeStore
 * @iter: (out): An unset #GtkTreeIter to set to the appended row
 * @parent: (allow-none): A valid #GtkTreeIter, or %NULL
 * 
 * Appends a new row to @tree_store.  If @parent is non-%NULL, then it will append the
 * new row after the last child of @parent, otherwise it will append a row to
 * the top level.  @iter will be changed to point to this new row.  The row will
 * be empty after this function is called.  To fill in values, you need to call
 * cm_tree_store_set() or cm_tree_store_set_value().
 **/
void
cm_tree_store_append (CMTreeStore *tree_store,
		       GtkTreeIter  *iter,
		       GtkTreeIter  *parent)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  CMNode *parent_node;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (iter != NULL);
  if (parent != NULL)
    g_return_if_fail (VALID_ITER (parent, tree_store));

  if (parent == NULL)
    parent_node = priv->root;
  else
    parent_node = parent->user_data;

  priv->columns_dirty = TRUE;

  if (parent_node->children == NULL)
    {
      GtkTreePath *path;

      iter->stamp = priv->stamp;
      iter->user_data = cm_node_new (NULL);
      iter->user_data2 = GINT_TO_POINTER (0);
      cm_node_append (parent_node, CM_NODE (iter->user_data));

  if (priv->emit_signals)
    {
      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_model_row_inserted (GTK_TREE_MODEL (tree_store), path, iter);

      if (parent_node != priv->root)
	{
	  gtk_tree_path_up (path);
	  gtk_tree_model_row_has_child_toggled (GTK_TREE_MODEL (tree_store), path, parent);
	}
      gtk_tree_path_free (path);
    }
    }
  else
    {
      cm_tree_store_insert_before (tree_store, iter, parent, NULL);
    }
}

void
cm_tree_store_emit_signals (CMTreeStore *tree_store,
			    gboolean emit)
{
  g_return_if_fail (CM_IS_TREE_STORE (tree_store));

  tree_store->priv->emit_signals = emit;
}

/**
 * cm_tree_store_is_ancestor:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter
 * @descendant: A valid #GtkTreeIter
 * 
 * Returns %TRUE if @iter is an ancestor of @descendant.  That is, @iter is the
 * parent (or grandparent or great-grandparent) of @descendant.
 * 
 * Return value: %TRUE, if @iter is an ancestor of @descendant
 **/
gboolean
cm_tree_store_is_ancestor (CMTreeStore *tree_store,
			    GtkTreeIter  *iter,
			    GtkTreeIter  *descendant)
{
  g_return_val_if_fail (CM_IS_TREE_STORE (tree_store), FALSE);
  g_return_val_if_fail (VALID_ITER (iter, tree_store), FALSE);
  g_return_val_if_fail (VALID_ITER (descendant, tree_store), FALSE);

  return cm_node_is_ancestor (CM_NODE (iter->user_data),
			     CM_NODE (descendant->user_data));
}


/**
 * cm_tree_store_iter_depth:
 * @tree_store: A #CMTreeStore
 * @iter: A valid #GtkTreeIter
 * 
 * Returns the depth of @iter.  This will be 0 for anything on the root level, 1
 * for anything down a level, etc.
 * 
 * Return value: The depth of @iter
 **/
gint
cm_tree_store_iter_depth (CMTreeStore *tree_store,
			   GtkTreeIter  *iter)
{
  g_return_val_if_fail (CM_IS_TREE_STORE (tree_store), 0);
  g_return_val_if_fail (VALID_ITER (iter, tree_store), 0);

  return cm_node_depth (CM_NODE (iter->user_data)) - 2;
}

static void
cm_tree_store_increment_stamp (CMTreeStore *tree_store)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  do
    {
      priv->stamp++;
    }
  while (priv->stamp == 0);
}

/**
 * cm_tree_store_clear:
 * @tree_store: a #CMTreeStore
 * 
 * Removes all rows from @tree_store
 **/
void
cm_tree_store_clear (CMTreeStore *tree_store)
{
  CMTreeStorePrivate *priv = tree_store->priv;
  g_return_if_fail (CM_IS_TREE_STORE (tree_store));

  g_hash_table_foreach (CM_NODE (priv->root)->children, node_data_free,
    priv->column_headers);
  cm_node_destroy (priv->root);
  priv->root = cm_node_new (NULL);
  cm_tree_store_increment_stamp (tree_store);
}

static gboolean
cm_tree_store_iter_is_valid_helper (GtkTreeIter *iter,
				     GtkTreeIter       *first)
{
  CMNode *node;
  gint i;

  node = CM_NODE (first->user_data);
  i = GPOINTER_TO_INT (first->user_data2);

  do
    {
      if (node == iter->user_data)
	return TRUE;

      if (node->children)
        {
      GtkTreeIter child_iter;
      CMNode *child;

      child = CM_NODE (g_hash_table_lookup (node->children, GINT_TO_POINTER (0)));
      child_iter.user_data = child;
      child_iter.user_data2 = GINT_TO_POINTER (0);
	  if (cm_tree_store_iter_is_valid_helper (iter, &child_iter))
	    return TRUE;
        }

      i += 1;

      node = CM_NODE (g_hash_table_lookup (node->parent->children,
          GINT_TO_POINTER (i)));
    }
  while (node);

  return FALSE;
}

/**
 * cm_tree_store_iter_is_valid:
 * @tree_store: A #CMTreeStore.
 * @iter: A #GtkTreeIter.
 *
 * WARNING: This function is slow. Only use it for debugging and/or testing
 * purposes.
 *
 * Checks if the given iter is a valid iter for this #CMTreeStore.
 *
 * Return value: %TRUE if the iter is valid, %FALSE if the iter is invalid.
 *
 * Since: 2.2
 **/
gboolean
cm_tree_store_iter_is_valid (CMTreeStore *tree_store,
                              GtkTreeIter  *iter)
{
  GtkTreeIter root_iter;
  CMNode *root;

  g_return_val_if_fail (CM_IS_TREE_STORE (tree_store), FALSE);
  g_return_val_if_fail (iter != NULL, FALSE);

  if (!VALID_ITER (iter, tree_store))
    return FALSE;

  root = tree_store->priv->root;
  if (!root->children)
    return FALSE;

  root = CM_NODE (g_hash_table_lookup (root->children, GINT_TO_POINTER (0)));
  root_iter.user_data = root;
  root_iter.user_data2 = GINT_TO_POINTER (0);

  return cm_tree_store_iter_is_valid_helper (iter, &root_iter);
}

/* DND */


static gboolean real_cm_tree_store_row_draggable (GtkTreeDragSource *drag_source,
                                                   GtkTreePath       *path)
{
  return TRUE;
}
               
static gboolean
cm_tree_store_drag_data_delete (GtkTreeDragSource *drag_source,
                                 GtkTreePath       *path)
{
  GtkTreeIter iter;

  if (cm_tree_store_get_iter (GTK_TREE_MODEL (drag_source),
                               &iter,
                               path))
    {
      GHashTable *hash = CM_NODE (iter.user_data)->parent->children;
      guint length = g_hash_table_size (hash);
      gint i;

      /* o well, got a better idea? please ... */
      g_hash_table_steal (hash, iter.user_data2);
      for (i = GPOINTER_TO_INT (iter.user_data2) + 1; i < length; i++)
        {
          gpointer data = g_hash_table_lookup (hash, GINT_TO_POINTER (i));
          g_hash_table_steal (hash, GINT_TO_POINTER (i));
          g_hash_table_insert (hash, GINT_TO_POINTER (i - 1), data);
        }
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

static gboolean
cm_tree_store_drag_data_get (GtkTreeDragSource *drag_source,
                              GtkTreePath       *path,
                              GtkSelectionData  *selection_data)
{
  /* Note that we don't need to handle the GTK_TREE_MODEL_ROW
   * target, because the default handler does it for us, but
   * we do anyway for the convenience of someone maybe overriding the
   * default handler.
   */

  if (gtk_tree_set_row_drag_data (selection_data,
				  GTK_TREE_MODEL (drag_source),
				  path))
    {
      return TRUE;
    }
  else
    {
      /* FIXME handle text targets at least. */
    }

  return FALSE;
}

static gboolean
cm_tree_store_drag_data_received (GtkTreeDragDest   *drag_dest,
                                   GtkTreePath       *dest,
                                   GtkSelectionData  *selection_data)
{
  GtkTreeModel *tree_model;
  CMTreeStore *tree_store;
  GtkTreeModel *src_model = NULL;
  GtkTreePath *src_path = NULL;
  gboolean retval = FALSE;

  tree_model = GTK_TREE_MODEL (drag_dest);
  tree_store = CM_TREE_STORE (drag_dest);

  if (gtk_tree_get_row_drag_data (selection_data,
				  &src_model,
				  &src_path) &&
      src_model == tree_model)
    {
      /* Copy the given row to a new position */
      GtkTreeIter src_iter;
      GtkTreeIter dest_iter;
      GtkTreePath *prev;

      if (!cm_tree_store_get_iter (src_model,
                                    &src_iter,
                                    src_path))
        {
          goto out;
        }

      /* Get the path to insert _after_ (dest is the path to insert _before_) */
      prev = gtk_tree_path_copy (dest);

      if (!gtk_tree_path_prev (prev))
        {
          GtkTreeIter dest_parent;
          GtkTreePath *parent;
          GtkTreeIter *dest_parent_p;
          CMNode *tmp_node, *dest_node;

          /* dest was the first spot at the current depth; which means
           * we are supposed to prepend.
           */

          /* Get the parent, NULL if parent is the root */
          dest_parent_p = NULL;
          parent = gtk_tree_path_copy (dest);
          if (gtk_tree_path_up (parent) &&
	      gtk_tree_path_get_depth (parent) > 0)
            {
              cm_tree_store_get_iter (tree_model,
                                       &dest_parent,
                                       parent);
              dest_parent_p = &dest_parent;
            }
          gtk_tree_path_free (parent);
          parent = NULL;

          tmp_node = cm_node_copy (CM_NODE (src_iter.user_data));
          cm_tree_store_prepend (tree_store,
                                  &dest_iter,
                                  dest_parent_p);
          dest_node = CM_NODE (dest_iter.user_data);
          dest_node->data = tmp_node->data;
          dest_node->children = tmp_node->children;
          cm_node_free(tmp_node);

          retval = TRUE;
        }
      else
        {
          if (cm_tree_store_get_iter (tree_model, &dest_iter, prev))
            {
              GtkTreeIter tmp_iter = dest_iter;
              CMNode *tmp_node, *dest_node;

              tmp_node = cm_node_copy (CM_NODE (src_iter.user_data));
              cm_tree_store_insert_after (tree_store, &dest_iter, NULL,
                                           &tmp_iter);
              dest_node = CM_NODE (dest_iter.user_data);
              dest_node->data = tmp_node->data;
              dest_node->children = tmp_node->children;
              cm_node_free(tmp_node);

              retval = TRUE;
            }
        }

      gtk_tree_path_free (prev);
    }
  else
    {
      /* FIXME maybe add some data targets eventually, or handle text
       * targets in the simple case.
       */

    }

 out:

  if (src_path)
    gtk_tree_path_free (src_path);

  return retval;
}

static gboolean
cm_tree_store_row_drop_possible (GtkTreeDragDest  *drag_dest,
                                  GtkTreePath      *dest_path,
				  GtkSelectionData *selection_data)
{
  GtkTreeModel *src_model = NULL;
  GtkTreePath *src_path = NULL;
  GtkTreePath *tmp = NULL;
  gboolean retval = FALSE;
  
  if (!gtk_tree_get_row_drag_data (selection_data,
				   &src_model,
				   &src_path))
    goto out;
    
  /* can only drag to ourselves */
  if (src_model != GTK_TREE_MODEL (drag_dest))
    goto out;

  /* Can't drop into ourself. */
  if (gtk_tree_path_is_ancestor (src_path,
                                 dest_path))
    goto out;

  /* Can't drop if dest_path's parent doesn't exist */
  {
    GtkTreeIter iter;

    if (gtk_tree_path_get_depth (dest_path) > 1)
      {
	tmp = gtk_tree_path_copy (dest_path);
	gtk_tree_path_up (tmp);
	
	if (!cm_tree_store_get_iter (GTK_TREE_MODEL (drag_dest),
				      &iter, tmp))
	  goto out;
      }
  }
  
  /* Can otherwise drop anywhere. */
  retval = TRUE;

 out:

  if (src_path)
    gtk_tree_path_free (src_path);
  if (tmp)
    gtk_tree_path_free (tmp);

  return retval;
}

/* Sorting and reordering */
typedef struct _SortTuple
{
  gint offset;
  CMNode *node;
} SortTuple;

typedef struct _SortTupleOrder
{
  SortTuple *list;
  gint *new_order;
} SortTupleOrder;

/* Reordering */
static gint
cm_tree_store_reorder_func (gconstpointer a,
			     gconstpointer b,
			     gpointer      user_data)
{
  SortTuple *a_reorder;
  SortTuple *b_reorder;

  a_reorder = (SortTuple *)a;
  b_reorder = (SortTuple *)b;

  if (a_reorder->offset < b_reorder->offset)
    return -1;
  if (a_reorder->offset > b_reorder->offset)
    return 1;

  return 0;
}

static void
cm_tree_store_neworder_func (gpointer key,
                 gpointer value,
                 gpointer data)
{
  SortTupleOrder *order = (SortTupleOrder *)data;
  SortTuple *sort_array = order->list;
  gint *new_order = order->new_order;
  gint i = GPOINTER_TO_INT (key);

  sort_array[new_order[i]].offset = i;
  sort_array[i].node = CM_NODE (value);
}

/**
 * cm_tree_store_reorder: (skip)
 * @tree_store: A #CMTreeStore.
 * @parent: A #GtkTreeIter.
 * @new_order: (array): an array of integers mapping the new position of each child
 *      to its old position before the re-ordering,
 *      i.e. @new_order<literal>[newpos] = oldpos</literal>.
 *
 * Reorders the children of @parent in @tree_store to follow the order
 * indicated by @new_order. Note that this function only works with
 * unsorted stores.
 *
 * Since: 2.2
 **/
void
cm_tree_store_reorder (CMTreeStore *tree_store,
			GtkTreeIter  *parent,
			gint         *new_order)
{
  gint i, length;
  GHashTable *level, *new_hash;
  GtkTreePath *path;
  SortTuple *sort_array;
  SortTupleOrder order;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (parent == NULL || VALID_ITER (parent, tree_store));
  g_return_if_fail (new_order != NULL);

  if (!parent)
    level = CM_NODE (tree_store->priv->root)->children;
  else
    level = CM_NODE (parent->user_data)->children;

  /* count nodes */
  length = g_hash_table_size (level);

  /* set up sortarray */
  sort_array = g_new (SortTuple, length);

  order.list = sort_array;
  order.new_order = new_order;

  g_hash_table_foreach(level, cm_tree_store_neworder_func, &order);

  g_qsort_with_data (sort_array,
		     length,
		     sizeof (SortTuple),
		     cm_tree_store_reorder_func,
		     NULL);

  /* fix up level */
  new_hash = g_hash_table_new_full (g_direct_hash, NULL, NULL, cm_node_destroy);
  for (i = 0; i < length; i++)
    g_hash_table_insert (new_hash, GINT_TO_POINTER (i), sort_array[i].node);
  g_hash_table_steal_all (level);
  g_hash_table_destroy (level);

  if (parent)
    CM_NODE (parent->user_data)->children = new_hash;
  else
    CM_NODE (tree_store->priv->root)->children = new_hash;

  /* emit signal */
  if (parent)
    path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), parent);
  else
    path = gtk_tree_path_new ();
  gtk_tree_model_rows_reordered (GTK_TREE_MODEL (tree_store), path,
				 parent, new_order);
  gtk_tree_path_free (path);
  g_free (sort_array);
}

/**
 * cm_tree_store_swap:
 * @tree_store: A #CMTreeStore.
 * @a: A #GtkTreeIter.
 * @b: Another #GtkTreeIter.
 *
 * Swaps @a and @b in the same level of @tree_store. Note that this function
 * only works with unsorted stores.
 *
 * Since: 2.2
 **/
void
cm_tree_store_swap (CMTreeStore *tree_store,
		     GtkTreeIter  *a,
		     GtkTreeIter  *b)
{
  CMNode *node_a, *node_b, *node_p;
  GtkTreePath *path_a, *path_b;
  GtkTreeIter parent;
  gint key_a, key_b, depth_a, depth_b;
  gint i, length, *order;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (VALID_ITER (a, tree_store));
  g_return_if_fail (VALID_ITER (b, tree_store));

  node_a = CM_NODE (a->user_data);
  node_b = CM_NODE (b->user_data);

  /* basic sanity checking */
  if (node_a == node_b)
    return;

  path_a = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), a);
  path_b = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), b);

  g_return_if_fail (path_a && path_b);

  gtk_tree_path_up (path_a);
  gtk_tree_path_up (path_b);

  depth_a = gtk_tree_path_get_depth (path_a);
  depth_b = gtk_tree_path_get_depth (path_b);
  if (depth_a == 0 || depth_b == 0)
    {
      if (depth_a != depth_b)
        {
          gtk_tree_path_free (path_a);
          gtk_tree_path_free (path_b);

          g_warning ("Given children are not in the same level\n");
          return;
        }
      node_p = CM_NODE (tree_store->priv->root);
    }
  else
    {
      if (gtk_tree_path_compare (path_a, path_b))
        {
          gtk_tree_path_free (path_a);
          gtk_tree_path_free (path_b);

          g_warning ("Given children don't have a common parent\n");
          return;
        }
      cm_tree_store_get_iter (GTK_TREE_MODEL (tree_store), &parent,
                               path_a);
      node_p = CM_NODE (parent.user_data);
    }
  gtk_tree_path_free (path_b);

  key_a = GPOINTER_TO_INT (a->user_data2);
  key_b = GPOINTER_TO_INT (b->user_data2);

  /* emit signal */
  length = g_hash_table_size (node_p->children);
  order  = g_new (gint, length);
  for (i = 0; i < length; i++)
    if (i == key_a)
      order[i] = key_b;
    else if (i == key_b)
      order[i] = key_a;
    else
      order[i] = i;

  gtk_tree_model_rows_reordered (GTK_TREE_MODEL (tree_store), path_a,
				 node_p == tree_store->priv->root
				 ? NULL : &parent, order);
  gtk_tree_path_free (path_a);
  g_free (order);
}

/* WARNING: this function is *incredibly* fragile. Please smashtest after
 * making changes here.
 *	-Kris
 */
static void
cm_tree_store_move (CMTreeStore *tree_store,
                     GtkTreeIter  *iter,
		     GtkTreeIter  *position,
		     gboolean      before)
{
  CMNodeForeach find;
  CMNode *parent, *node, *a, *b, *tmp, *tmp_a, *tmp_b;
  GtkTreePath *path = NULL, *tmppath, *pos_path = NULL;
  GtkTreeIter parent_iter, dst_a, dst_b;
  gint old_pos, new_pos, length, i, *order, depth = 0;
  gboolean handle_b = TRUE;

  g_return_if_fail (CM_IS_TREE_STORE (tree_store));
  g_return_if_fail (VALID_ITER (iter, tree_store));
  if (position)
    g_return_if_fail (VALID_ITER (position, tree_store));

  a = b = NULL;

  /* sanity checks */
  if (position)
    {
      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      pos_path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store),
	                                  position);

      /* if before:
       *   moving the iter before path or "path + 1" doesn't make sense
       * else
       *   moving the iter before path or "path - 1" doesn't make sense
       */
      if (!gtk_tree_path_compare (path, pos_path))
	goto free_paths_and_out;

      if (before)
        gtk_tree_path_next (path);
      else
        gtk_tree_path_prev (path);

      if (!gtk_tree_path_compare (path, pos_path))
	goto free_paths_and_out;

      if (before)
        gtk_tree_path_prev (path);
      else
        gtk_tree_path_next (path);

      if (gtk_tree_path_get_depth (path) != gtk_tree_path_get_depth (pos_path))
        {
          g_warning ("Given children are not in the same level\n");

	  goto free_paths_and_out;
        }

      tmppath = gtk_tree_path_copy (pos_path);
      gtk_tree_path_up (path);
      gtk_tree_path_up (tmppath);

      if (gtk_tree_path_get_depth (path) > 0 &&
	  gtk_tree_path_compare (path, tmppath))
        {
          g_warning ("Given children are not in the same level\n");

          gtk_tree_path_free (tmppath);
	  goto free_paths_and_out;
        }

      gtk_tree_path_free (tmppath);
    }

  if (!path)
    {
      path = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), iter);
      gtk_tree_path_up (path);
    }

  depth = gtk_tree_path_get_depth (path);

  if (depth)
    {
      cm_tree_store_get_iter (GTK_TREE_MODEL (tree_store), 
			       &parent_iter, path);

      parent = CM_NODE (parent_iter.user_data);
    }
  else
    parent = CM_NODE (tree_store->priv->root);

  /* yes, I know that this can be done shorter, but I'm doing it this way
   * so the code is also maintainable
   */

  if (before && position)
    {
      b = CM_NODE (position->user_data);

      if (gtk_tree_path_get_indices (pos_path)[gtk_tree_path_get_depth (pos_path) - 1] > 0)
        {
          gtk_tree_path_prev (pos_path);
          if (cm_tree_store_get_iter (GTK_TREE_MODEL (tree_store), 
				       &dst_a, pos_path))
            a = CM_NODE (dst_a.user_data);
          else
            a = NULL;
          gtk_tree_path_next (pos_path);
	}

      /* if b is NULL, a is NULL too -- we are at the beginning of the list
       * yes and we leak memory here ...
       */
      g_return_if_fail (b);
    }
  else if (before && !position)
    {
      /* move before without position is appending */
      a = NULL;
      b = NULL;
    }
  else /* !before */
    {
      if (position)
        a = CM_NODE (position->user_data);
      else
        a = NULL;

      if (position)
        {
          gtk_tree_path_next (pos_path);
          if (cm_tree_store_get_iter (GTK_TREE_MODEL (tree_store), &dst_b, pos_path))
             b = CM_NODE (dst_b.user_data);
          else
             b = NULL;
          gtk_tree_path_prev (pos_path);
	}
      else
        {
	  /* move after without position is prepending */
	  if (depth)
	    cm_tree_store_iter_children (GTK_TREE_MODEL (tree_store), &dst_b,
	                                  &parent_iter);
	  else
	    cm_tree_store_iter_children (GTK_TREE_MODEL (tree_store), &dst_b,
		                          NULL);

	  b = CM_NODE (dst_b.user_data);
	}

      /* if a is NULL, b is NULL too -- we are at the end of the list
       * yes and we leak memory here ...
       */
      if (position)
        g_return_if_fail (a);
    }

  /* counting nodes */
  length = g_hash_table_size (parent->children);

  find.data = iter->user_data;

  old_pos = 0;
  if (g_hash_table_find (parent->children, cm_node_find_child_func, &find))
    old_pos = length;

  /* emit signal */
  if (position)
    new_pos = gtk_tree_path_get_indices (pos_path)[gtk_tree_path_get_depth (pos_path)-1];
  else if (before)
    {
      if (depth)
        new_pos = cm_tree_store_iter_n_children (GTK_TREE_MODEL (tree_store),
	                                          &parent_iter) - 1;
      else
	new_pos = cm_tree_store_iter_n_children (GTK_TREE_MODEL (tree_store),
	                                          NULL) - 1;
    }
  else
    new_pos = 0;

  if (new_pos > old_pos)
    {
      if (before && position)
        new_pos--;
    }
  else
    {
      if (!before && position)
        new_pos++;
    }

  order = g_new (gint, length);
  if (new_pos > old_pos)
    {
      for (i = 0; i < length; i++)
        if (i < old_pos)
          order[i] = i;
        else if (i >= old_pos && i < new_pos)
          order[i] = i + 1;
        else if (i == new_pos)
          order[i] = old_pos;
        else
	  order[i] = i;
    }
  else
    {
      for (i = 0; i < length; i++)
        if (i == new_pos)
	  order[i] = old_pos;
        else if (i > new_pos && i <= old_pos)
	  order[i] = i - 1;
	else
	  order[i] = i;
    }

  if (depth)
    {
      tmppath = cm_tree_store_get_path (GTK_TREE_MODEL (tree_store), 
					 &parent_iter);
      gtk_tree_model_rows_reordered (GTK_TREE_MODEL (tree_store),
				     tmppath, &parent_iter, order);
    }
  else
    {
      tmppath = gtk_tree_path_new ();
      gtk_tree_model_rows_reordered (GTK_TREE_MODEL (tree_store),
				     tmppath, NULL, order);
    }

  gtk_tree_path_free (tmppath);
  gtk_tree_path_free (path);
  if (position)
    gtk_tree_path_free (pos_path);
  g_free (order);

  return;

free_paths_and_out:
  gtk_tree_path_free (path);
  gtk_tree_path_free (pos_path);
}

/**
 * cm_tree_store_move_before:
 * @tree_store: A #CMTreeStore.
 * @iter: A #GtkTreeIter.
 * @position: (allow-none): A #GtkTreeIter or %NULL.
 *
 * Moves @iter in @tree_store to the position before @position. @iter and
 * @position should be in the same level. Note that this function only
 * works with unsorted stores. If @position is %NULL, @iter will be
 * moved to the end of the level.
 *
 * Since: 2.2
 **/
void
cm_tree_store_move_before (CMTreeStore *tree_store,
                            GtkTreeIter  *iter,
			    GtkTreeIter  *position)
{
  cm_tree_store_move (tree_store, iter, position, TRUE);
}

/**
 * cm_tree_store_move_after:
 * @tree_store: A #CMTreeStore.
 * @iter: A #GtkTreeIter.
 * @position: (allow-none): A #GtkTreeIter.
 *
 * Moves @iter in @tree_store to the position after @position. @iter and
 * @position should be in the same level. Note that this function only
 * works with unsorted stores. If @position is %NULL, @iter will be moved
 * to the start of the level.
 *
 * Since: 2.2
 **/
void
cm_tree_store_move_after (CMTreeStore *tree_store,
                           GtkTreeIter  *iter,
			   GtkTreeIter  *position)
{
  cm_tree_store_move (tree_store, iter, position, FALSE);
}

/* GtkBuildable custom tag implementation
 *
 * <columns>
 *   <column type="..."/>
 *   <column type="..."/>
 * </columns>
 */
typedef struct {
  GtkBuilder *builder;
  GObject *object;
  GSList *items;
} GSListSubParserData;

static void
tree_model_start_element (GMarkupParseContext *context,
			  const gchar         *element_name,
			  const gchar        **names,
			  const gchar        **values,
			  gpointer            user_data,
			  GError            **error)
{
  guint i;
  GSListSubParserData *data = (GSListSubParserData*)user_data;

  for (i = 0; names[i]; i++)
    {
      if (strcmp (names[i], "type") == 0)
	data->items = g_slist_prepend (data->items, g_strdup (values[i]));
    }
}

static void
tree_model_end_element (GMarkupParseContext *context,
			const gchar         *element_name,
			gpointer             user_data,
			GError             **error)
{
  GSListSubParserData *data = (GSListSubParserData*)user_data;

  g_assert(data->builder);

  if (strcmp (element_name, "columns") == 0)
    {
      GSList *l;
      GType *types;
      int i;
      GType type;

      data = (GSListSubParserData*)user_data;
      data->items = g_slist_reverse (data->items);
      types = g_new0 (GType, g_slist_length (data->items));

      for (l = data->items, i = 0; l; l = l->next, i++)
        {
          type = gtk_builder_get_type_from_name (data->builder, l->data);
          if (type == G_TYPE_INVALID)
            {
              g_warning ("Unknown type %s specified in treemodel %s",
                         (const gchar*)l->data,
                         gtk_buildable_get_name (GTK_BUILDABLE (data->object)));
              continue;
            }
          types[i] = type;

          g_free (l->data);
        }

      cm_tree_store_set_column_types (CM_TREE_STORE (data->object), i, types);

      g_free (types);
    }
}

static const GMarkupParser tree_model_parser =
  {
    tree_model_start_element,
    tree_model_end_element
  };


static gboolean
cm_tree_store_buildable_custom_tag_start (GtkBuildable  *buildable,
					   GtkBuilder    *builder,
					   GObject       *child,
					   const gchar   *tagname,
					   GMarkupParser *parser,
					   gpointer      *data)
{
  GSListSubParserData *parser_data;

  if (child)
    return FALSE;

  if (strcmp (tagname, "columns") == 0)
    {
      parser_data = g_slice_new0 (GSListSubParserData);
      parser_data->builder = builder;
      parser_data->items = NULL;
      parser_data->object = G_OBJECT (buildable);

      *parser = tree_model_parser;
      *data = parser_data;
      return TRUE;
    }

  return FALSE;
}

static void
cm_tree_store_buildable_custom_finished (GtkBuildable *buildable,
					  GtkBuilder   *builder,
					  GObject      *child,
					  const gchar  *tagname,
					  gpointer      user_data)
{
  GSListSubParserData *data;

  if (strcmp (tagname, "columns"))
    return;

  data = (GSListSubParserData*)user_data;

  g_slist_free (data->items);
  g_slice_free (GSListSubParserData, data);
}
