/*
 *         Author: Hanno Meyer-Thurow <h.mth@web.de>
 *
 *        Purpose: Test GtkTreeModel implementations.
 *
 *                 Claws Mail summary view needs a performant model able to
 *                 manage elements exceeding tens or hundreds of thousands.
 *
 *                 There are surely other applications in need for testing trees.
 *
 *        Version: 0.x
 *
 * Contributor(s): None
 *
 *
 * Based on the work of tadeboro <tadeboro@gmail.com>
 *
 *     http://tadeboro.blogspot.com/2009/05/gtktreemodel-and-filtering-4.html
 *
 *
 * Based on the guide for custom GtkTreeModel implementations
 *
 *     http://scentric.net/tutorial/sec-custom-models.html
 *
 *
 * This program is distributed under the terms of the GNU General Public License.
 * For more info see http://www.gnu.org/licenses/gpl.txt.
 */

/*
 * COMPILE
 
 *  GTk+ 2.x
       gcc -O2 -march=native -pipe gtktreemodel_performance.c \
           cmnode.c cmtreestore.c gtktreedatalist.c \
           -o /usr/local/bin/gtktreemodel-performance \
           $(pkg-config --cflags --libs gtk+-2.0)
 
 *  GTk+ 3.x
       gcc -O2 -march=native -pipe gtktreemodel_performance.c \
           cmnode.c cmtreestore.c gtktreedatalist.c \
           -o /usr/local/bin/gtktreemodel-performance \
           $(pkg-config --cflags --libs gtk+-3.0 cairo)
 */

/*
 * HACKING
 *
 * If you feel like hacking on this code, please follow current coding style.
 * If you see a violation to proper coding styles, please report it to me!
 *
 * Your changes must be stored as a unified diff.
 * The easiest way to do so is to checkout this subversion repository and do a:
 *
 *     svn diff scripts/gtktreemodel_performance.c > changes.diff
 *
 * This is necessary to integrate your work smoothly.
 *
 * Please send your changes with description to my email address above.
 */

#include <gtk/gtk.h>
#include <stdlib.h>
#include <string.h>

#include "cmtreestore.h"

typedef struct _ListRowData ListRowData;
typedef struct _Data Data;

struct _ListRowData
{
	gchar *name;

	ListRowData *next;
	ListRowData *prev;
};

struct _Data
{
	GtkWidget *button;
	GtkWidget *entry;

	GtkTreeView  *tree;
	GtkTreeModel *store;
	GtkTreeModel *filter;
	GtkTreeModel *sort;

	struct _ListRowData data;
};

static create_data(Data *data);
static destroy_data(Data *data);

static GtkTreeModel * create_store(Data *data);
static void fill_store(GtkTreeModel *store, Data *data);

static GtkTreeModel * create_filter(GtkTreeModel *store, GtkEntry *entry);
static gboolean do_refilter(GtkTreeModelFilter *filter);
static void queue_refilter(GtkTreeModelFilter *filter);

static GtkTreeModel * create_sort(GtkTreeModel *store);

static void cb_changed(GtkEditable *entry, Data *data);
static void cb_clicked(GtkButton *button, Data *data);

static gint sort_func(GtkTreeModel *model, GtkTreeIter *a, GtkTreeIter *b,
	gpointer userdata);
static gboolean visible_func(GtkTreeModel *model, GtkTreeIter *iter,
	GtkEntry *entry);

static gint timeout_id = 0;

static create_data(Data *data)
{
	ListRowData *row;
	ListRowData *prev;

	gchar *name, *file;

	g_file_get_contents("names.txt", &file, NULL, NULL);

	data->data.name = NULL;
	data->data.next = NULL;
	data->data.prev = NULL;

	prev = &data->data;
	for (name = strtok(file, ","); name; name = strtok(NULL, ","))
	{
		row = (ListRowData *)malloc(sizeof(ListRowData));

		row->name = g_strdup(name);
		row->next = NULL;
		row->prev = prev;

		prev->next = row;
		prev = row;
	}

	prev->prev->next = NULL;
	free(prev);

	g_free(file);
}

static destroy_data(Data *data)
{
	ListRowData* prev;
	ListRowData* root;

	root = &data->data;

	while(root->next)
	{
		prev = root->next;
		root->next = prev->next;

		g_free(prev->name);
		free(prev);
	}
}

GtkTreeModel * create_store(Data* data)
{
	GtkTreeModel *store;

	store = GTK_TREE_MODEL(cm_tree_store_new(1, G_TYPE_STRING));

	fill_store(store, data);

	return store;
}

static void fill_store(GtkTreeModel *store, Data *data)
{
	ListRowData *prev;

	gchar *name;

	gint64 start, end, j;
	gint i;

	start = g_get_monotonic_time();

	for(i = 0, j = 0; i < 1; i++)
	{
		GtkTreeIter parent;

		prev = data->data.next;
		name = prev->name;

		if (name)
		{
			cm_tree_store_append(CM_TREE_STORE(store), &parent, NULL);
			cm_tree_store_set(CM_TREE_STORE(store), &parent, 0, name, -1);
			j++;

			for (prev = prev->next; prev; prev = prev->next)
			{
				GtkTreeIter iter;

				cm_tree_store_append(CM_TREE_STORE(store), &iter, NULL);
				cm_tree_store_set(CM_TREE_STORE(store), &iter, 0, prev->name, -1);
				j++;
			}
		}
	}

	end = g_get_monotonic_time();
	g_print("populate: (%ld) %ld µs\n", j, end - start);
}

GtkTreeModel * create_filter(GtkTreeModel *store, GtkEntry *entry)
{
	GtkTreeModel *filter;

	filter = GTK_TREE_MODEL(gtk_tree_model_filter_new(store, NULL));
	gtk_tree_model_filter_set_visible_func(GTK_TREE_MODEL_FILTER(filter),
		(GtkTreeModelFilterVisibleFunc)visible_func, entry, NULL);

	return filter;
}

gboolean do_refilter(GtkTreeModelFilter *filter)
{
	gint64 start, end;

	start = g_get_monotonic_time();

	gtk_tree_model_filter_refilter(filter);

	end = g_get_monotonic_time();
	g_print("filter: %ld µs\n", end - start);

	timeout_id = 0;

	return FALSE;
}

void queue_refilter(GtkTreeModelFilter *filter)
{
	if (timeout_id)
		g_source_remove(timeout_id);

	timeout_id = g_timeout_add(300, (GSourceFunc)do_refilter, filter);
}

GtkTreeModel * create_sort(GtkTreeModel *store)
{
	GtkTreeModel *sort;

	sort = GTK_TREE_MODEL(gtk_tree_model_sort_new_with_model(store));
	gtk_tree_sortable_set_sort_func(GTK_TREE_SORTABLE(sort), 0,
		(GtkTreeIterCompareFunc)sort_func, GINT_TO_POINTER(0), NULL);
	gtk_tree_sortable_set_sort_column_id(GTK_TREE_SORTABLE(sort), 0,
		GTK_SORT_ASCENDING);

	return sort;
}

void cb_changed(GtkEditable *entry, Data *data)
{
	queue_refilter(GTK_TREE_MODEL_FILTER(data->filter));
}

void cb_clicked(GtkButton *button, Data *data)
{
	GtkTreeView *tree;
	GtkTreeModel *store;
	GtkTreeModel *filter;
	GtkTreeModel *sort;

	gint64 start, create, end;

	start = g_get_monotonic_time();

	tree   = data->tree;

	sort   = gtk_tree_view_get_model(tree);
	filter = gtk_tree_model_sort_get_model(GTK_TREE_MODEL_SORT(sort));
	store  = gtk_tree_model_filter_get_model(GTK_TREE_MODEL_FILTER(filter));

	g_object_unref(G_OBJECT(sort));
	g_object_unref(G_OBJECT(filter));

	gtk_tree_view_set_model(tree, NULL);
	cm_tree_store_clear(CM_TREE_STORE(store));

	end = g_get_monotonic_time();
	g_print("clear: %ld µs\n", end - start);

	fill_store(store, data);

	filter = create_filter(store, GTK_ENTRY(data->entry));
	sort   = create_sort(filter);

	create = g_get_monotonic_time();

	/* model sort: performance depending on the filter?!
	 * 			   the longer the filter the faster the redraw
	 *
	 * => this needs some love!
	 */
	gtk_tree_view_set_model(tree, sort);

	end = g_get_monotonic_time();
	g_print("create: %ld µs\n", end - create);

	data->filter = filter;
	data->sort   = sort;

	end = g_get_monotonic_time();
	g_print("rebuilt: %ld µs\n", end - start);
}

gint sort_func(GtkTreeModel *model, GtkTreeIter *a, GtkTreeIter *b,
	gpointer userdata)
{
	gchar *name1, *name2;

	gint result = 0;

	gtk_tree_model_get(model, a, 0, &name1, -1);
	gtk_tree_model_get(model, b, 0, &name2, -1);
 
	if (name1 == NULL)
	{
		if (name2 != NULL)
			result = -1;
	}
	else if (name2 == NULL)
	{
		if (name1 != NULL)
			result =  1;
	}
	else
	{
		result = strcmp(name1, name2);
	}

	g_free(name1);
	g_free(name2);

	return result;
}

gboolean visible_func(GtkTreeModel *model, GtkTreeIter *iter,
	GtkEntry *entry)
{
	const gchar *needle;
	gchar *haystack;
	gboolean result;

	needle = gtk_entry_get_text(entry);

	if (*needle == '\0')
		return TRUE;

	gtk_tree_model_get(model, iter, 0, &haystack, -1);

	result = strstr(haystack, needle) ? TRUE : FALSE;
	g_free(haystack);

	return result;
}

int main(int argc, char *argv[])
{
	Data data;

	GtkWidget *window;
	GtkWidget *vbox;
	GtkWidget *button;
	GtkWidget *entry;
	GtkWidget *swindow;
	GtkWidget* tree;

	GtkTreeModel* store;
	GtkTreeModel* filter;
	GtkTreeModel* sort;

	GtkCellRenderer *cell;

	gchar *name, *file;

	create_data(&data);

	gtk_init(&argc, &argv);

	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	g_signal_connect(G_OBJECT(window), "delete-event",
		G_CALLBACK(destroy_data), &data);
	g_signal_connect(G_OBJECT(window), "destroy",
		G_CALLBACK(gtk_main_quit), NULL);

	vbox = gtk_vbox_new(FALSE, 6);
	gtk_container_add(GTK_CONTAINER(window), vbox);

	button = gtk_button_new_with_label("Repopulate");
	gtk_box_pack_start(GTK_BOX(vbox), button, FALSE, FALSE, 0);

	entry = gtk_entry_new();
	gtk_box_pack_start(GTK_BOX(vbox), entry, FALSE, FALSE, 0);

	swindow = gtk_scrolled_window_new(NULL, NULL);
	gtk_box_pack_start(GTK_BOX(vbox), swindow, TRUE, TRUE, 0);

	store  = create_store(&data);
	filter = create_filter(store, GTK_ENTRY(entry));
	sort   = create_sort(filter);

	tree = gtk_tree_view_new_with_model(sort);
	gtk_container_add(GTK_CONTAINER(swindow), tree);

	cell = gtk_cell_renderer_text_new();
	gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(tree), -1,
		"Name", cell, "text", 0, NULL);

	gtk_tree_view_column_set_sort_column_id(
		gtk_tree_view_get_column(GTK_TREE_VIEW(tree), 0), 0);

	g_signal_connect(G_OBJECT(entry), "changed", G_CALLBACK(cb_changed), &data);
	g_signal_connect(G_OBJECT(button),"clicked", G_CALLBACK(cb_clicked), &data);

	data.button = button;
	data.entry  = entry;

	data.tree   = GTK_TREE_VIEW(tree);
	data.store  = store;
	data.filter = filter;
	data.sort   = sort;

	gtk_widget_show_all(window);
	gtk_main();

	return 0;
}

