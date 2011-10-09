/* gtktreedatalist.c
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
 * 
 * This file contains code shared between GtkTreeStore and GtkListStore.  Please
 * do not use it.
 */

#include "gtktreedatalist.h"
#include <string.h>

/* node allocation
 */
GtkTreeDataList *
_gtk_tree_data_list_alloc (void)
{
  GtkTreeDataList *list;

  list = g_slice_new0 (GtkTreeDataList);

  return list;
}

void
_gtk_tree_data_list_free (GtkTreeDataList *list,
			  GType           *column_headers)
{
  GtkTreeDataList *tmp, *next;
  gint i = 0;

  tmp = list;

  while (tmp)
    {
      next = tmp->next;
      if (g_type_is_a (column_headers [i], G_TYPE_STRING))
	g_free ((gchar *) tmp->data.v_pointer);
      else if (g_type_is_a (column_headers [i], G_TYPE_OBJECT) && tmp->data.v_pointer != NULL)
	g_object_unref (tmp->data.v_pointer);
      else if (g_type_is_a (column_headers [i], G_TYPE_BOXED) && tmp->data.v_pointer != NULL)
	g_boxed_free (column_headers [i], (gpointer) tmp->data.v_pointer);
      else if (g_type_is_a (column_headers [i], G_TYPE_VARIANT) && tmp->data.v_pointer != NULL)
	g_variant_unref ((gpointer) tmp->data.v_pointer);

      g_slice_free (GtkTreeDataList, tmp);
      i++;
      tmp = next;
    }
}

gboolean
_gtk_tree_data_list_check_type (GType type)
{
  gint i = 0;
  static const GType type_list[] =
  {
    G_TYPE_BOOLEAN,
    G_TYPE_CHAR,
    G_TYPE_UCHAR,
    G_TYPE_INT,
    G_TYPE_UINT,
    G_TYPE_LONG,
    G_TYPE_ULONG,
    G_TYPE_INT64,
    G_TYPE_UINT64,
    G_TYPE_ENUM,
    G_TYPE_FLAGS,
    G_TYPE_FLOAT,
    G_TYPE_DOUBLE,
    G_TYPE_STRING,
    G_TYPE_POINTER,
    G_TYPE_BOXED,
    G_TYPE_OBJECT,
    G_TYPE_VARIANT,
    G_TYPE_INVALID
  };

  if (! G_TYPE_IS_VALUE_TYPE (type))
    return FALSE;


  while (type_list[i] != G_TYPE_INVALID)
    {
      if (g_type_is_a (type, type_list[i]))
	return TRUE;
      i++;
    }
  return FALSE;
}

static inline GType
get_fundamental_type (GType type)
{
  GType result;

  result = G_TYPE_FUNDAMENTAL (type);

  if (result == G_TYPE_INTERFACE)
    {
      if (g_type_is_a (type, G_TYPE_OBJECT))
	result = G_TYPE_OBJECT;
    }

  return result;
}
void
_gtk_tree_data_list_node_to_value (GtkTreeDataList *list,
				   GType            type,
				   GValue          *value)
{
  g_value_init (value, type);

  switch (get_fundamental_type (type))
    {
    case G_TYPE_BOOLEAN:
      g_value_set_boolean (value, (gboolean) list->data.v_int);
      break;
    case G_TYPE_CHAR:
      g_value_set_char (value, (gchar) list->data.v_char);
      break;
    case G_TYPE_UCHAR:
      g_value_set_uchar (value, (guchar) list->data.v_uchar);
      break;
    case G_TYPE_INT:
      g_value_set_int (value, (gint) list->data.v_int);
      break;
    case G_TYPE_UINT:
      g_value_set_uint (value, (guint) list->data.v_uint);
      break;
    case G_TYPE_LONG:
      g_value_set_long (value, list->data.v_long);
      break;
    case G_TYPE_ULONG:
      g_value_set_ulong (value, list->data.v_ulong);
      break;
    case G_TYPE_INT64:
      g_value_set_int64 (value, list->data.v_int64);
      break;
    case G_TYPE_UINT64:
      g_value_set_uint64 (value, list->data.v_uint64);
      break;
    case G_TYPE_ENUM:
      g_value_set_enum (value, list->data.v_int);
      break;
    case G_TYPE_FLAGS:
      g_value_set_flags (value, list->data.v_uint);
      break;
    case G_TYPE_FLOAT:
      g_value_set_float (value, (gfloat) list->data.v_float);
      break;
    case G_TYPE_DOUBLE:
      g_value_set_double (value, (gdouble) list->data.v_double);
      break;
    case G_TYPE_STRING:
      g_value_set_string (value, (gchar *) list->data.v_pointer);
      break;
    case G_TYPE_POINTER:
      g_value_set_pointer (value, (gpointer) list->data.v_pointer);
      break;
    case G_TYPE_BOXED:
      g_value_set_boxed (value, (gpointer) list->data.v_pointer);
      break;
    case G_TYPE_VARIANT:
      g_value_set_variant (value, (gpointer) list->data.v_pointer);
      break;
    case G_TYPE_OBJECT:
      g_value_set_object (value, (GObject *) list->data.v_pointer);
      break;
    default:
      g_warning ("%s: Unsupported type (%s) retrieved.", G_STRLOC, g_type_name (value->g_type));
      break;
    }
}

void
_gtk_tree_data_list_value_to_node (GtkTreeDataList *list,
				   GValue          *value)
{
  switch (get_fundamental_type (G_VALUE_TYPE (value)))
    {
    case G_TYPE_BOOLEAN:
      list->data.v_int = g_value_get_boolean (value);
      break;
    case G_TYPE_CHAR:
      list->data.v_char = g_value_get_char (value);
      break;
    case G_TYPE_UCHAR:
      list->data.v_uchar = g_value_get_uchar (value);
      break;
    case G_TYPE_INT:
      list->data.v_int = g_value_get_int (value);
      break;
    case G_TYPE_UINT:
      list->data.v_uint = g_value_get_uint (value);
      break;
    case G_TYPE_LONG:
      list->data.v_long = g_value_get_long (value);
      break;
    case G_TYPE_ULONG:
      list->data.v_ulong = g_value_get_ulong (value);
      break;
    case G_TYPE_INT64:
      list->data.v_int64 = g_value_get_int64 (value);
      break;
    case G_TYPE_UINT64:
      list->data.v_uint64 = g_value_get_uint64 (value);
      break;
    case G_TYPE_ENUM:
      list->data.v_int = g_value_get_enum (value);
      break;
    case G_TYPE_FLAGS:
      list->data.v_uint = g_value_get_flags (value);
      break;
    case G_TYPE_POINTER:
      list->data.v_pointer = g_value_get_pointer (value);
      break;
    case G_TYPE_FLOAT:
      list->data.v_float = g_value_get_float (value);
      break;
    case G_TYPE_DOUBLE:
      list->data.v_double = g_value_get_double (value);
      break;
    case G_TYPE_STRING:
      g_free (list->data.v_pointer);
      list->data.v_pointer = g_value_dup_string (value);
      break;
    case G_TYPE_OBJECT:
      if (list->data.v_pointer)
	g_object_unref (list->data.v_pointer);
      list->data.v_pointer = g_value_dup_object (value);
      break;
    case G_TYPE_BOXED:
      if (list->data.v_pointer)
	g_boxed_free (G_VALUE_TYPE (value), list->data.v_pointer);
      list->data.v_pointer = g_value_dup_boxed (value);
      break;
    case G_TYPE_VARIANT:
      if (list->data.v_pointer)
	g_variant_unref (list->data.v_pointer);
      list->data.v_pointer = g_value_dup_variant (value);
      break;
    default:
      g_warning ("%s: Unsupported type (%s) stored.", G_STRLOC, g_type_name (G_VALUE_TYPE (value)));
      break;
    }
}

GtkTreeDataList *
_gtk_tree_data_list_node_copy (GtkTreeDataList *list,
                               GType            type)
{
  GtkTreeDataList *new_list;

  g_return_val_if_fail (list != NULL, NULL);
  
  new_list = _gtk_tree_data_list_alloc ();
  new_list->next = NULL;

  switch (get_fundamental_type (type))
    {
    case G_TYPE_BOOLEAN:
    case G_TYPE_CHAR:
    case G_TYPE_UCHAR:
    case G_TYPE_INT:
    case G_TYPE_UINT:
    case G_TYPE_LONG:
    case G_TYPE_ULONG:
    case G_TYPE_INT64:
    case G_TYPE_UINT64:
    case G_TYPE_ENUM:
    case G_TYPE_FLAGS:
    case G_TYPE_POINTER:
    case G_TYPE_FLOAT:
    case G_TYPE_DOUBLE:
      new_list->data = list->data;
      break;
    case G_TYPE_STRING:
      new_list->data.v_pointer = g_strdup (list->data.v_pointer);
      break;
    case G_TYPE_OBJECT:
    case G_TYPE_INTERFACE:
      new_list->data.v_pointer = list->data.v_pointer;
      if (new_list->data.v_pointer)
	g_object_ref (new_list->data.v_pointer);
      break;
    case G_TYPE_BOXED:
      if (list->data.v_pointer)
	new_list->data.v_pointer = g_boxed_copy (type, list->data.v_pointer);
      else
	new_list->data.v_pointer = NULL;
      break;
    case G_TYPE_VARIANT:
      if (list->data.v_pointer)
	new_list->data.v_pointer = g_variant_ref (list->data.v_pointer);
      else
	new_list->data.v_pointer = NULL;
      break;
    default:
      g_warning ("Unsupported node type (%s) copied.", g_type_name (type));
      break;
    }

  return new_list;
}

