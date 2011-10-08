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
           -o /usr/local/bin/gtktreemodel-performance \
           $(pkg-config --cflags --libs gtk+-2.0)
 
 *  GTk+ 3.x
       gcc -O2 -march=native -pipe gtktreemodel_performance.c \
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

typedef struct _Data Data;
typedef struct _ListRowData ListRowData;

struct _Data
{
	GtkWidget *button;
	GtkWidget *entry;

	GtkTreeView  *tree;
	GtkTreeModel *store;
	GtkTreeModel *filter;
};

struct _ListRowData
{
	gchar *name;

	struct _ListRowData *next;
	struct _ListRowData *prev;
};

static GtkTreeModel * create_store();
static void fill_store(GtkTreeModel *store);

static GtkTreeModel * create_filter(GtkTreeModel *store, GtkEntry *entry);
static gboolean do_refilter(GtkTreeModelFilter *filter);
static void queue_refilter(GtkTreeModelFilter *filter);

static void cb_changed(GtkEditable *entry, Data *data);
static void cb_clicked(GtkButton *button, Data *data);

static gboolean visible_func(GtkTreeModel *model, GtkTreeIter *iter,
	GtkEntry *entry);

static gint timeout_id = 0;

GtkTreeModel * create_store()
{
	GtkTreeModel *store;

	store = GTK_TREE_MODEL(gtk_list_store_new(1, G_TYPE_STRING));

	fill_store(store);

	return store;
}

static void fill_store(GtkTreeModel *store)
{
	ListRowData  rows;
	ListRowData *row;
	ListRowData *prev;

	gchar *name, *file;

	gint64 start, end, j;
	gint i;

	rows.name = NULL;
	rows.next = NULL;
	rows.prev = NULL;

	g_file_get_contents("names.txt", &file, NULL, NULL);

	prev = &rows;
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

	start = g_get_monotonic_time();

	for(i = 0, j = 0; i < 1; i++)
	{
		GtkTreeIter parent;

		prev = rows.next;
		name = prev->name;

		if (name)
		{
			gtk_list_store_append(GTK_LIST_STORE(store), &parent);//, NULL);
			gtk_list_store_set(GTK_LIST_STORE(store), &parent, 0, name, -1);
			j++;

			for (prev = prev->next; prev; prev = prev->next)
			{
				GtkTreeIter iter;

				gtk_list_store_append(GTK_LIST_STORE(store), &iter);//, NULL);
				gtk_list_store_set(GTK_LIST_STORE(store), &iter, 0, prev->name, -1);
				j++;
			}
		}
	}

	end = g_get_monotonic_time();
	g_print("populate: (%ld) %ld µs\n", j, end - start);

	while(rows.next)
	{
		prev = rows.next;
		rows.next = prev->next;

		g_free(prev->name);
		free(prev);
	}
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

void cb_changed(GtkEditable *entry, Data *data)
{
	queue_refilter(GTK_TREE_MODEL_FILTER(data->filter));
}

void cb_clicked(GtkButton *button, Data *data)
{
	GtkTreeView *tree;
	GtkTreeModel *store;
	GtkTreeModel *filter;

	gint64 start, end;

	tree   = data->tree;

	start = g_get_monotonic_time();

	/* FIXME: performance hit: remove and attach store/filter to tree
	 *		  what is the proper way?
	 */
	filter = gtk_tree_view_get_model(tree);
	store  = gtk_tree_model_filter_get_model(GTK_TREE_MODEL_FILTER(filter));

	gtk_tree_view_set_model(tree, NULL);
	gtk_list_store_clear(GTK_LIST_STORE(store));

	end = g_get_monotonic_time();
	g_print("clear: %ld µs\n", end - start);

	fill_store(store);

	gtk_tree_view_set_model(tree, filter);
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

	GtkCellRenderer *cell;

	gchar *name, *file;

	gtk_init(&argc, &argv);

	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
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

	store = create_store();
	filter = create_filter(store, GTK_ENTRY(entry));

	tree = gtk_tree_view_new_with_model(filter);
	gtk_container_add(GTK_CONTAINER(swindow), tree);

	cell = gtk_cell_renderer_text_new();
	gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(tree), -1,
		"Name", cell, "text", 0, NULL);

	g_signal_connect(G_OBJECT(entry), "changed", G_CALLBACK(cb_changed), &data);
	g_signal_connect(G_OBJECT(button),"clicked", G_CALLBACK(cb_clicked), &data);

	data.tree   = GTK_TREE_VIEW(tree);
	data.store  = store;
	data.filter = filter;

	gtk_widget_show_all(window);
	gtk_main();

	return 0;
}

