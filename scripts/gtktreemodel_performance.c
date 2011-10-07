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
#include <string.h>

static gboolean do_refilter(GtkTreeModelFilter *filter);
static void queue_refilter(GtkTreeModelFilter *filter);

static void cb_clicked(GtkButton *button, GtkTreeView *tree);
static void cb_changed(GtkEditable *entry, GtkTreeModelFilter *filter);

static gboolean visible_func(GtkTreeModel *model, GtkTreeIter *iter,
	GtkEntry *entry);

static gint timeout_id = 0;

void cb_clicked(GtkButton *button, GtkTreeView *tree)
{
	GtkTreeModel *filter;
	GtkListStore *store;

	gchar *name, *file;
	gint64 start, end;

	start = g_get_monotonic_time();

	filter = gtk_tree_view_get_model(tree);
	store = GTK_LIST_STORE(gtk_tree_model_filter_get_model(GTK_TREE_MODEL_FILTER(filter)));

	g_object_ref(G_OBJECT(store));
	gtk_tree_view_set_model(tree, NULL);
	gtk_list_store_clear(store);

	g_file_get_contents("names.txt", &file, NULL, NULL);
	for (name = strtok(file, ","); name; name = strtok(NULL, ","))
	{
		GtkTreeIter iter;

		gtk_list_store_append(store, &iter);
		gtk_list_store_set(store, &iter, 0, name, -1);

		name = strtok(NULL, ",");
	}
	g_free(file);

	filter = gtk_tree_model_filter_new(GTK_TREE_MODEL(store), NULL);
	g_object_unref(G_OBJECT(store));

	gtk_tree_view_set_model(tree, filter);
	g_object_unref(G_OBJECT(filter));

	end = g_get_monotonic_time();

	g_print("populate: %ld µs\n", end - start);
}

gboolean do_refilter(GtkTreeModelFilter *filter)
{
	g_print("Refiltering...");
	gtk_tree_model_filter_refilter(filter);
	g_print("done\n");

	timeout_id = 0;

	return FALSE;
}

void queue_refilter(GtkTreeModelFilter *filter)
{
	if (timeout_id)
		g_source_remove(timeout_id);

	timeout_id = g_timeout_add(300, (GSourceFunc)do_refilter, filter);
}

void cb_changed(GtkEditable *entry, GtkTreeModelFilter *filter)
{
	queue_refilter(filter);
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
	GtkWidget *window;
	GtkWidget *vbox;
	GtkWidget *button;
	GtkWidget *entry;
	GtkWidget *swindow;
	GtkWidget *tree;

	GtkListStore *store;
	GtkTreeModel *filter;

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

	store = gtk_list_store_new(1, G_TYPE_STRING);

	g_file_get_contents("names.txt", &file, NULL, NULL);
	for (name = strtok(file, ","); name; name = strtok(NULL, ","))
	{
		GtkTreeIter iter;

		gtk_list_store_append(store, &iter);
		gtk_list_store_set(store, &iter, 0, name, -1);

		name = strtok(NULL, ",");
	}
	g_free(file);

	filter = gtk_tree_model_filter_new(GTK_TREE_MODEL(store), NULL);
	g_object_unref(G_OBJECT(store));
	gtk_tree_model_filter_set_visible_func(GTK_TREE_MODEL_FILTER(filter),
		(GtkTreeModelFilterVisibleFunc)visible_func, GTK_ENTRY(entry),
		NULL);

	tree = gtk_tree_view_new_with_model(filter);
	g_object_unref(G_OBJECT(filter));
	gtk_container_add(GTK_CONTAINER(swindow), tree);

	cell = gtk_cell_renderer_text_new();
	gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(tree), -1,
		"Name", cell, "text", 0, NULL);

	g_signal_connect(G_OBJECT(button), "clicked", G_CALLBACK(cb_clicked),
		GTK_TREE_VIEW(tree));
	g_signal_connect(G_OBJECT(entry), "changed", G_CALLBACK(cb_changed),
		GTK_TREE_MODEL_FILTER(filter));

	gtk_widget_show_all(window);
	gtk_main();

	return 0;
}

