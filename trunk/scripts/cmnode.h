/* GLIB - Library of useful routines for C programming
 * Copyright (C) 1995-1997  Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.     See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*
 * Modified by the GLib Team and others 1997-2000.  See the AUTHORS
 * file for a list of people on the GLib Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GLib at ftp://ftp.gtk.org/pub/gtk/.
 */

#ifndef __CM_NODE_H__
#define __CM_NODE_H__

#include <glib.h>

G_BEGIN_DECLS

typedef struct _CMNode         CMNode;
typedef struct _CMNodeForeach  CMNodeForeach;
typedef struct _CMNodeTraverse CMNodeTraverse;

/*
 * CMNodeTraverseFunc/CMNodeForeachFunc
 * @key: of the GHashTable value
 * @value: stored in the GHashTable
 * @data: CMNodeTraverse structure. Its data field holds your object
 *
 * You have to implement the GTraverseFlags logic within your function, i.e.:

    CMNode *node = CM_NODE(value);
    gpointer obj = CM_NODE_TRAVERSE(data)->data;
    GTraverseFlags flags = CM_NODE_TRAVERSE(data)->flags;

    if (node->data == obj)
      {
        if (CM_NODE_IS_LEAF (node))
          {
            if (flags & G_TRAVERSE_LEAFS)
              ...
          }
        else
          {
            if (flags & G_TRAVERSE_NON_LEAFS)
              ...
          }
      }

 */
typedef gboolean (*CMNodeTraverseFunc) (gpointer key,
                      gpointer value,
                      gpointer data);
typedef void     (*CMNodeForeachFunc)  (gpointer key,
                      gpointer value,
                      gpointer data);


/* N-way tree implementation
 */
struct _CMNode
{
  gpointer    data;
  CMNode     *parent;
  GHashTable *children;
};

struct _CMNodeForeach
{
  GTraverseFlags flags;
  gpointer       data;
};

struct _CMNodeTraverse
{
  GTraverseType  order;
  GTraverseFlags flags;
  guint          depth;
  gpointer       data;
};

#define CM_NODE(node)              ((CMNode *)node)
#define CM_NODE_FOREACH(traverse)  ((CMNodeForeach *)traverse)
#define CM_NODE_TRAVERSE(traverse) ((CMNodeTraverse *)traverse)

#define cm_node_free(node)         g_slice_free (CMNode, node)

/**
 * CM_NODE_IS_ROOT:
 * @node: a #CMNode
 *
 * Returns %TRUE if a #CMNode is the root of a tree.
 *
 * Returns: %TRUE if the #CMNode is the root of a tree 
 *     (i.e. it has no parent or siblings)
 */
#define CM_NODE_IS_ROOT(node)      (((CMNode*) (node))->parent == NULL)

/**
 * CM_NODE_IS_LEAF:
 * @node: a #CMNode
 *
 * Returns %TRUE if a #CMNode is a leaf node.
 *
 * Returns: %TRUE if the #CMNode is a leaf node 
 *     (i.e. it has no children)
 */
#define CM_NODE_IS_LEAF(node)      (((CMNode*) (node))->children == NULL)

CMNode*  cm_node_new            (gpointer data);
void     cm_node_destroy        (gpointer data);
void     cm_node_unlink         (CMNode  *node);
CMNode*  cm_node_copy           (CMNode  *node);
CMNode*  cm_node_append         (CMNode  *parent,
                                 CMNode  *node);
guint    cm_node_n_nodes        (CMNode  *root,
                         GTraverseFlags   flags);
CMNode*  cm_node_get_root       (CMNode  *node);
gboolean cm_node_is_ancestor    (CMNode  *node,
                                 CMNode  *descendant);
guint    cm_node_depth          (CMNode  *node);

CMNode*  cm_node_find           (CMNode  *root,
                          GTraverseType   order,
                         GTraverseFlags   flags,
                                   gint   depth,
                     CMNodeTraverseFunc   func,
                               gpointer   data);
void     cm_node_foreach        (CMNode  *node,
                         GTraverseFlags   flags,
                      CMNodeForeachFunc   func,
                               gpointer   data);

/**
 * cm_node_append_data:
 * @parent: the #CMNode to place the new #CMNode under
 * @data: the data for the new #CMNode
 *
 * Inserts a new #CMNode as the last child of the given parent.
 *
 * Returns: the new #CMNode
 */
#define  cm_node_append_data(parent, data) \
    cm_node_append ((parent), cm_node_new (data))

/* return the maximum tree height starting with `node', this is an expensive
 * operation, since we need to visit all nodes. this could be shortened by
 * adding `guint height' to struct _CMNode, but then again, this is not very
 * often needed, and would make cm_node_insert() more time consuming.
 */
guint    cm_node_max_height     (CMNode  *root);

guint    cm_node_n_children     (CMNode  *node);
CMNode*  cm_node_nth_child      (CMNode  *node,
                                  guint   n);
CMNode*  cm_node_last_child     (CMNode  *node);
gint     cm_node_child_position (CMNode  *node,
                                 CMNode  *child);
gint     cm_node_child_index    (CMNode  *node,
                               gpointer   data);

CMNode*  cm_node_first_sibling  (CMNode  *node);
CMNode*  cm_node_last_sibling   (CMNode  *node);

G_END_DECLS

#endif /* __CM_NODE_H__ */
