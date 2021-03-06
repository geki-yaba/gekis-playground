/* GLIB - Library of useful routines for C programming
 * Copyright (C) 1995-1997  Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * CMNode: N-way tree implementation.
 * Copyright (C) 1998 Tim Janik
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

/*
 * MT safe
 */

#include "cmnode.h"

/**
 * SECTION:trees-nary
 * @title: N-ary Trees
 * @short_description: trees of data with any number of branches
 *
 * The #CMNode struct and its associated functions provide a N-ary tree
 * data structure, where nodes in the tree can contain arbitrary data.
 *
 * To create a new tree use cm_node_new().
 *
 * To insert a node into a tree use cm_node_insert(),
 * cm_node_insert_before(), cm_node_append() and cm_node_prepend().
 *
 * To create a new node and insert it into a tree use
 * cm_node_insert_data(), cm_node_insert_data_before(),
 * cm_node_append_data() and cm_node_prepend_data().
 *
 * To reverse the children of a node use cm_node_reverse_children().
 *
 * To find a node use cm_node_get_root(), cm_node_find(),
 * cm_node_find_child(), cm_node_child_index(), cm_node_child_position(),
 * cm_node_first_child(), cm_node_last_child(), cm_node_nth_child(),
 * cm_node_first_sibling(), cm_node_prev_sibling(), cm_node_next_sibling()
 * or cm_node_last_sibling().
 *
 * To get information about a node or tree use CM_NODE_IS_LEAF(),
 * CM_NODE_IS_ROOT(), cm_node_depth(), cm_node_n_nodes(),
 * cm_node_n_children(), cm_node_is_ancestor() or cm_node_max_height().
 *
 * To traverse a tree, calling a function for each node visited in the
 * traversal, use cm_node_traverse() or cm_node_foreach().
 *
 * To remove a node or subtree from a tree use cm_node_unlink() or
 * cm_node_destroy().
 **/

/**
 * CMNode:
 * @data: contains the actual data of the node.
 * @next: points to the node's next sibling (a sibling is another
 *        #CMNode with the same parent).
 * @prev: points to the node's previous sibling.
 * @parent: points to the parent of the #CMNode, or is %NULL if the
 *          #CMNode is the root of the tree.
 * @children: points to the first child of the #CMNode.  The other
 *            children are accessed by using the @next pointer of each
 *            child.
 *
 * The #CMNode struct represents one node in a
 * <link linkend="glib-N-ary-Trees">N-ary Tree</link>. fields
 **/

#define cm_node_alloc0()         g_slice_new0 (CMNode)

/* --- functions --- */
/**
 * cm_node_new:
 * @data: the data of the new node
 *
 * Creates a new #CMNode containing the given data.
 * Used to create the first node in a tree.
 *
 * Returns: a new #CMNode
 */
CMNode*
cm_node_new (gpointer data)
{
  CMNode *node = cm_node_alloc0 ();
  node->data = data;
  return node;
}

static void
cm_nodes_free (CMNode *node)
{
  if (node->children)
    g_hash_table_unref (node->children);
  cm_node_free (node);
}

/**
 * cm_node_destroy:
 * @root: the root of the tree/subtree to destroy
 *
 * Removes @root and its children from the tree, freeing any memory
 * allocated.
 */
void
cm_node_destroy (gpointer data)
{
  CMNode *root = CM_NODE (data);

  g_return_if_fail (root != NULL);

  if (!CM_NODE_IS_ROOT (root))
    root->parent = NULL;

  cm_nodes_free (root);
}

/**
 * cm_node_unlink:
 * @node: the #CMNode to unlink, which becomes the root of a new tree
 *
 * Unlinks a #CMNode from a tree, resulting in two separate trees.
 */
void
cm_node_unlink (CMNode *node)
{
  g_return_if_fail (node != NULL);
  
  if (node->parent)
    {
      gint n;

      n = cm_node_child_position (node->parent, node);

      if (n >= 0)
        g_hash_table_steal (node->parent->children, GINT_TO_POINTER(n));
    }
  node->parent = NULL;
}

/**
 * cm_node_copy:
 * @node: a #CMNode
 *
 * Recursively copies a #CMNode (but does not deep-copy the data inside the 
 * nodes, see cm_node_copy_deep() if you need that).
 *
 * Returns: a new #CMNode containing the same data pointers
 */
CMNode*
cm_node_copy (CMNode *node)
{
  CMNode *new_node = NULL;
  
  if (node)
    {
      new_node = cm_node_new (node->data);
      
      if (node->children)
        new_node->children = g_hash_table_ref (node->children);
    }
  
  return new_node;
}

/**
 * cm_node_append:
 * @parent: the #CMNode to place @node under
 * @sibling: the sibling #CMNode to place @node before. 
 * @node: the #CMNode to insert
 *
 * Inserts a #CMNode beneath the parent before the given sibling.
 *
 * Returns: the inserted #CMNode
 */
CMNode*
cm_node_append (CMNode *parent,
        CMNode *node)
{
  guint i = 0;

  g_return_val_if_fail (parent != NULL, node);
  g_return_val_if_fail (node != NULL, node);
  g_return_val_if_fail (CM_NODE_IS_ROOT (node), node);
  
  node->parent = parent;
  
  if (parent->children)
    i = g_hash_table_size (parent->children);
  else
    parent->children =
      g_hash_table_new_full (g_direct_hash, NULL, NULL, cm_node_destroy);

  g_hash_table_insert (parent->children, GUINT_TO_POINTER (i), node);

  return node;
}

/**
 * cm_node_get_root:
 * @node: a #CMNode
 *
 * Gets the root of a tree.
 *
 * Returns: the root of the tree
 */
CMNode*
cm_node_get_root (CMNode *node)
{
  g_return_val_if_fail (node != NULL, NULL);
  
  while (node->parent)
    node = node->parent;
  
  return node;
}

/**
 * cm_node_is_ancestor:
 * @node: a #CMNode
 * @descendant: a #CMNode
 *
 * Returns %TRUE if @node is an ancestor of @descendant.
 * This is true if node is the parent of @descendant, 
 * or if node is the grandparent of @descendant etc.
 *
 * Returns: %TRUE if @node is an ancestor of @descendant
 */
gboolean
cm_node_is_ancestor (CMNode *node,
        CMNode *descendant)
{
  g_return_val_if_fail (node != NULL, FALSE);
  g_return_val_if_fail (descendant != NULL, FALSE);
  
  while (descendant)
    {
      if (descendant->parent == node)
    return TRUE;
      
      descendant = descendant->parent;
    }
  
  return FALSE;
}

/**
 * cm_node_depth:
 * @node: a #CMNode
 *
 * Gets the depth of a #CMNode.
 *
 * If @node is %NULL the depth is 0. The root node has a depth of 1.
 * For the children of the root node the depth is 2. And so on.
 *
 * Returns: the depth of the #CMNode
 */
guint
cm_node_depth (CMNode *node)
{
  guint depth = 0;
  
  while (node)
    {
      depth++;
      node = node->parent;
    }
  
  return depth;
}

/**
 * cm_node_find:
 * @root: the root #CMNode of the tree to search
 * @order: the order in which nodes are visited - %G_IN_ORDER, 
 *     %G_PRE_ORDER, %G_POST_ORDER, or %G_LEVEL_ORDER
 * @flags: which types of children are to be searched, one of 
 *     %G_TRAVERSE_ALL, %G_TRAVERSE_LEAVES and %G_TRAVERSE_NON_LEAVES
 * @data: the data to find
 *
 * Finds a #CMNode in a tree.
 *
 * Returns: the found #CMNode, or %NULL if the data is not found
 */
CMNode*
cm_node_find (CMNode      *root,
        GTraverseType      order,
        GTraverseFlags     flags,
        gint               depth,
        CMNodeTraverseFunc func,
        gpointer           data)
{
  CMNodeTraverse traverse;

  g_return_val_if_fail (root != NULL, NULL);
  g_return_val_if_fail (root->children != NULL, NULL);
  g_return_val_if_fail (order <= G_LEVEL_ORDER, NULL);
  g_return_val_if_fail (flags <= G_TRAVERSE_MASK, NULL);
  g_return_val_if_fail (depth == -1 || depth > 0, NULL);
  g_return_val_if_fail (func != NULL, NULL);

  traverse.order = order;
  traverse.flags = flags;
  traverse.depth = depth;
  traverse.data  = data;
  
  return g_hash_table_find (root->children, func, &traverse);
}

/**
 * cm_node_foreach:
 * @node: a #CMNode
 * @flags: which types of children are to be visited, one of 
 *     %G_TRAVERSE_ALL, %G_TRAVERSE_LEAVES and %G_TRAVERSE_NON_LEAVES
 * @func: the function to call for each visited node
 * @data: user data to pass to the function
 *
 * Calls a function for each of the children of a #CMNode.
 * Note that it doesn't descend beneath the child nodes.
 */
/**
 * CMNodeForeachFunc:
 * @node: a #CMNode.
 * @data: user data passed to cm_node_foreach().
 *
 * Specifies the type of function passed to cm_node_foreach().
 * The function is called with each child node, together with the user
 * data passed to cm_node_foreach().
 **/
void
cm_node_foreach (CMNode  *node,
        GTraverseFlags    flags,
        CMNodeForeachFunc func,
        gpointer          data)
{
  CMNodeForeach traverse;

  g_return_if_fail (node != NULL);
  g_return_if_fail (node->children != NULL);
  g_return_if_fail (func != NULL);

  traverse.flags = flags;
  traverse.data  =  data;

  g_hash_table_foreach (node->children, func, &traverse);
}

gboolean
cm_node_find_child_func (gpointer key,
        gpointer value,
        gpointer data)
{
  CMNodeForeach *find = CM_NODE_FOREACH (data);
  CMNode *node  = CM_NODE (value);

  if (node == find->data)
    {
      find->data = key;
      return TRUE;
    }

  return FALSE;
}

gboolean
cm_node_find_child_data_func (gpointer key,
        gpointer value,
        gpointer data)
{
  CMNodeForeach *find = CM_NODE_FOREACH (data);
  CMNode *node  = CM_NODE (value);

  if (node->data == find->data)
    {
      find->data = key;
      return TRUE;
    }

  return FALSE;
}

static void
cm_node_foreach_count_func (gpointer key,
        gpointer value,
        gpointer data)
{
  CMNode *node = CM_NODE (value);
  guint *n = (guint *)(CM_NODE_FOREACH(data)->data);
  GTraverseFlags flags = CM_NODE_FOREACH(data)->flags;

  if (node->children)
    {
      if (flags & G_TRAVERSE_NON_LEAFS)
        (*n)++;

      g_hash_table_foreach (node->children, cm_node_foreach_count_func, data);
    }
  else if (flags & G_TRAVERSE_LEAFS)
    (*n)++;
}

static void
cm_node_foreach_height_func (gpointer key,
        gpointer value,
        gpointer data)
{
  CMNode *node = CM_NODE (value);
  guint *max_height = (guint *)(CM_NODE_FOREACH(data)->data);
  guint tmp_height;

  /* there may be a better way */
  tmp_height = cm_node_max_height (node);
  if (tmp_height > *max_height)
    *max_height = tmp_height;
}

/**
 * cm_node_n_nodes:
 * @root: a #CMNode
 * @flags: which types of children are to be counted, one of 
 *     %G_TRAVERSE_ALL, %G_TRAVERSE_LEAVES and %G_TRAVERSE_NON_LEAVES
 *
 * Gets the number of nodes in a tree.
 *
 * Returns: the number of nodes in the tree
 */
guint
cm_node_n_nodes (CMNode *root,
        GTraverseFlags   flags)
{
  guint n = 0;

  g_return_val_if_fail (root != NULL, 0);
  g_return_val_if_fail (root->children != NULL, 0);
  g_return_val_if_fail (flags <= G_TRAVERSE_MASK, 0);

  cm_node_foreach (root, flags, cm_node_foreach_count_func, &n);

  return n;
}

/**
 * cm_node_max_height:
 * @root: a #CMNode
 *
 * Gets the maximum height of all branches beneath a #CMNode.
 * This is the maximum distance from the #CMNode to all leaf nodes.
 *
 * If @root is %NULL, 0 is returned. If @root has no children, 
 * 1 is returned. If @root has children, 2 is returned. And so on.
 *
 * Returns: the maximum height of the tree beneath @root
 */
guint
cm_node_max_height (CMNode *root)
{
  guint max_height = 0;

  g_return_val_if_fail (root != NULL, 0);
  g_return_val_if_fail (root->children != NULL, 1);

  cm_node_foreach (root, G_TRAVERSE_ALL, cm_node_foreach_height_func, &max_height);

  return max_height + 1;
}

/**
 * cm_node_last_child:
 * @node: a #CMNode (must not be %NULL)
 *
 * Gets the last child of a #CMNode.
 *
 * Returns: the last child of @node, or %NULL if @node has no children
 */
CMNode*
cm_node_last_child (CMNode *node)
{
  guint nth;

  g_return_val_if_fail (node != NULL, NULL);
  g_return_val_if_fail (node->children != NULL, NULL);

  nth  = g_hash_table_size (node->children);

  return cm_node_nth_child (node, nth);
}

/**
 * cm_node_n_children:
 * @node: a #CMNode
 *
 * Gets the number of children of a #CMNode.
 *
 * Returns: the number of children of @node
 */
guint
cm_node_n_children (CMNode *node)
{
  guint n = 0;

  g_return_val_if_fail (node != NULL, 0);
  g_return_val_if_fail (node->children != NULL, 0);

  return g_hash_table_size(node->children);
}

/**
 * cm_node_nth_child:
 * @node: a #CMNode
 * @n: the index of the desired child
 *
 * Gets a child of a #CMNode, using the given index.
 * The first child is at index 0. If the index is 
 * too big, %NULL is returned.
 *
 * Returns: the child of @node at index @n
 */
CMNode*
cm_node_nth_child (CMNode *node,
        guint n)
{
  g_return_val_if_fail (node != NULL, NULL);
  g_return_val_if_fail (node->children != NULL, NULL);

  return CM_NODE (g_hash_table_lookup (node->children, GUINT_TO_POINTER (n)));
}

/**
 * cm_node_child_position:
 * @node: a #CMNode
 * @child: a child of @node
 *
 * Gets the position of a #CMNode with respect to its siblings.
 * @child must be a child of @node. The first child is numbered 0, 
 * the second 1, and so on.
 *
 * Returns: the position of @child with respect to its siblings
 */
gint
cm_node_child_position (CMNode *node,
        CMNode *child)
{
  CMNodeForeach find;

  g_return_val_if_fail (node != NULL, -1);
  g_return_val_if_fail (child != NULL, -1);
  g_return_val_if_fail (child->parent == node, -1);
  g_return_val_if_fail (node->children != NULL, -1);

  find.data = child;

  if (g_hash_table_find (node->children, cm_node_find_child_func, &find))
    return GPOINTER_TO_INT (find.data);

  return -1;
}

/**
 * cm_node_child_index:
 * @node: a #CMNode
 * @data: the data to find
 *
 * Gets the position of the first child of a #CMNode 
 * which contains the given data.
 *
 * Returns: the index of the child of @node which contains 
 *     @data, or -1 if the data is not found
 */
gint
cm_node_child_index (CMNode *node,
        gpointer data)
{
  CMNodeForeach find;

  g_return_val_if_fail (node != NULL, -1);
  g_return_val_if_fail (node->children != NULL, -1);

  find.data = data;

  if (g_hash_table_find (node->children, cm_node_find_child_data_func, &find))
    return GPOINTER_TO_INT (find.data);

  return -1;
}

/**
 * cm_node_first_sibling:
 * @node: a #CMNode
 *
 * Gets the first sibling of a #CMNode.
 * This could possibly be the node itself.
 *
 * Returns: the first sibling of @node
 */
CMNode*
cm_node_first_sibling (CMNode *node)
{
  g_return_val_if_fail (node != NULL, NULL);

  if (node->parent)
    return CM_NODE (g_hash_table_lookup (node->parent->children, GINT_TO_POINTER (0)));

  return node;
}

/**
 * cm_node_last_sibling:
 * @node: a #CMNode
 *
 * Gets the last sibling of a #CMNode.
 * This could possibly be the node itself.
 *
 * Returns: the last sibling of @node
 */
CMNode*
cm_node_last_sibling (CMNode *node)
{
  g_return_val_if_fail (node != NULL, NULL);

  if (node->parent)
    return cm_node_last_child (node->parent);

  return node;
}
