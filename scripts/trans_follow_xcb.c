/*
 *		 Author: Hanno Meyer-Thurow <h.mth@web.de>
 *
 *		Purpose: Set opacity for all windows.
 *				 The focused window is opaque.
 *
 *		Version: 0.1.x
 *
 * Contributor(s): None
 *
 * Based on the work of ADcomp <david.madbox@gmail.com> [ http://www.ad-comp.be/ ]
 * with extra bits by Benj1 <holroyd.ben@gmail.com>
 *
 *	 http://crunchbanglinux.org/forums/post/33142/#p33142
 *
 * This program is distributed under the terms of the GNU General Public License.
 * For more info see http://www.gnu.org/licenses/gpl.txt.
 */

/*
 * COMPILE
 
	   gcc -O2 -march=native -pipe scripts/trans_follow_xcb.c \
		   -o /usr/local/bin/trans-follow $(pkg-config --libs xcb xcb-icccm)
 */

/*
 * EXECUTE
 *
 * trans-follow
 *
 *	 sets opacity to 0.75, no programs to ignore
 *
 * trans-follow <opacity>
 *
 *	 sets opacity to <opacity>, no programs to ignore
 *
 * trans-follow <opacity> [ <ignore program> | ... ]
 *
 *	 sets opacity to <opacity>, programs to ignore
 *
 *
 * Example:
 *
 *	 trans-follow 0.654 Firefox MPlayer
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
 *	 svn diff scripts/trans_follow_xcb.c > changes.diff
 *
 * This is necessary to integrate your work smoothly.
 *
 * Please send your changes with description to my email address above.
 */

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <xcb/xcb.h>
#include <xcb/xcb_event.h>
#include <xcb/xcb_icccm.h>
#include <xcb/xproto.h>

typedef struct xcb_config_ignore_list_t {
	unsigned int length;
	char* name;
	struct xcb_config_ignore_list_t* next;
} xcb_config_ignore_list_t;

typedef struct xcb_atom_list_t {
	xcb_intern_atom_cookie_t cookie;
	xcb_atom_t atom;
	struct xcb_atom_list_t* next;
} xcb_atom_list_t;

typedef struct xcb_config_t {
	int error;
	int screen_no;
	float opacity;
	xcb_connection_t* connection;
	xcb_screen_t* screen;
	xcb_window_t window;
	xcb_atom_list_t* list;
	xcb_config_ignore_list_t* ignore;
} xcb_config_t;

/* signal handler data */
static xcb_config_t* global = NULL;

int  xcb_config_run(int argc, char* argv[]);
void xcb_config_parse(xcb_config_t* config, int argc, char* argv[]);
int  xcb_config_error(xcb_config_t* config);
void xcb_config_command(char const* command);
void xcb_config_command_wrapper(xcb_window_t window, float opacity);
int  xcb_config_init(xcb_config_t* config);
void xcb_config_uninit(xcb_config_t* config);
int  xcb_config_valid_window(xcb_config_t* config, xcb_window_t window);
void xcb_config_find_parent(xcb_config_t* config, xcb_window_t* child);
void xcb_config_set_all_opaque(xcb_config_t* config);
void xcb_config_set_atom(xcb_config_t* config, char const* atom);
void xcb_config_set_error(xcb_config_t* config, int error);
void xcb_config_set_event_mask(xcb_config_t* config,
	uint16_t mask, uint32_t* values);
void xcb_config_event_loop(xcb_config_t* config);
int  xcb_config_event_property_notify(xcb_config_t* config,
	xcb_generic_event_t* event);
void xcb_config_event_property_update(xcb_config_t* config);

void register_signal_handlers();
static void signal_handler(int signal);

int main(int argc, char* argv[])
{
	return xcb_config_run(argc, argv);
}

int  xcb_config_run(int argc, char* argv[])
{
	const unsigned int size = 1;

	uint16_t mask;
	uint32_t values[size];

	xcb_config_t config;

	register_signal_handlers();

	int error = xcb_config_init(&config);

	if (! error)
	{
		xcb_config_parse(&config, argc, argv);

		mask = XCB_CW_EVENT_MASK;
		values[0] = XCB_EVENT_MASK_PROPERTY_CHANGE;

		xcb_config_set_event_mask(&config, mask, values);
		xcb_config_set_atom(&config, "_NET_CURRENT_DESKTOP");
		xcb_config_set_atom(&config, "_NET_ACTIVE_WINDOW");

		xcb_config_event_loop(&config);
	}

	xcb_config_uninit(&config);

	return error;
}

void xcb_config_parse(xcb_config_t* config, int argc, char* argv[])
{
	int i;
	float opacity;

	xcb_config_ignore_list_t* ignore;

	if (argc > 1)
	{
		sscanf(argv[1], "%5f", &opacity);

		if ((0.0f > opacity) || (opacity > .999f))
			opacity = .999f;
	}
	else
		opacity = 0.75f;

	config->opacity = opacity;

	if (argc > 2)
	{
		for(i = 2; i < argc; i++)
		{
			ignore = (xcb_config_ignore_list_t*)
				malloc(sizeof(xcb_config_ignore_list_t));

			/* evil? feel free to improve! :) */
			ignore->length = sizeof(argv[i]);
			ignore->name = argv[i];
			ignore->next = config->ignore;
			config->ignore = ignore;
		}
	}
}

int xcb_config_error(xcb_config_t* config)
{
	return config->error;
}

void xcb_config_command(char const* command)
{
	int ignore = system(command);
}

void xcb_config_command_wrapper(xcb_window_t window, float opacity)
{
	char buffer[40];
	int count;

	count = sprintf(buffer, "transset -i 0x%x %1.3f", window, opacity);

	buffer[count] = '\0';

	xcb_config_command(buffer);
}

int  xcb_config_init(xcb_config_t* config)
{
	int i;

	config->connection = xcb_connect(NULL, &config->screen_no);
	xcb_config_set_error(config, xcb_connection_has_error(config->connection));

	config->opacity = .999f;
	config->screen = NULL;
	config->window = XCB_WINDOW_NONE;
	config->list = NULL;
	config->ignore = NULL;

	if (! xcb_config_error(config))
	{
		/* register as global for signal handler */
		global = config;

		xcb_setup_t const* setup = xcb_get_setup(config->connection);
		xcb_screen_iterator_t iterator = xcb_setup_roots_iterator(setup);  

		for(i = 0; i < config->screen_no; i++)
			xcb_screen_next(&iterator);

		config->screen = iterator.data;

		if (! config->screen)
			xcb_config_set_error(config, 1);
	}

	return xcb_config_error(config);
}

void xcb_config_uninit(xcb_config_t* config)
{
	xcb_atom_list_t* list;
	xcb_config_ignore_list_t* ignore;

	while(config->list)
	{
		list = config->list;
		config->list = list->next;

		free(list);
	}

	while(config->ignore)
	{
		ignore = config->ignore;
		config->ignore = ignore->next;

		free(ignore);
	}

	if (! xcb_connection_has_error(config->connection))
	{
		xcb_config_set_all_opaque(config);

		xcb_disconnect(config->connection);
	}
}

int  xcb_config_valid_window(xcb_config_t* config, xcb_window_t window)
{
	xcb_get_geometry_cookie_t cookie =
		xcb_get_geometry_unchecked(config->connection, window);
	xcb_get_geometry_reply_t* reply =
		xcb_get_geometry_reply(config->connection, cookie, NULL);

	if (reply)
		free(reply);
	else
		return 0;

	return 1;
}

void xcb_config_find_parent(xcb_config_t* config, xcb_window_t* child)
{
	const uint32_t class = 0xffff0000;
	uint32_t class_child, class_parent;

	xcb_window_t parent;

	xcb_query_tree_cookie_t cookie =
		xcb_query_tree_unchecked(config->connection, *child);
	xcb_query_tree_reply_t* reply =
		xcb_query_tree_reply(config->connection, cookie, NULL);

	while(reply)
	{
		parent = reply->parent;

		free(reply);

		class_child = *child & class;
		class_parent = parent & class;

		/* not proper but simple :) */
		if (class_child == class_parent)
			*child  = parent;
		else
			break;

		cookie = xcb_query_tree_unchecked(config->connection, *child);
		reply = xcb_query_tree_reply(config->connection, cookie, NULL);
	}
}

void xcb_config_set_all_opaque(xcb_config_t* config)
{
	unsigned int i;
	unsigned int children;

	xcb_window_t* window;

	xcb_query_tree_cookie_t cookie =
		xcb_query_tree_unchecked(config->connection, config->screen->root);
	xcb_query_tree_reply_t* tree =
		xcb_query_tree_reply(config->connection, cookie, NULL);

	if (tree)
	{
		children = xcb_query_tree_children_length(tree);
		window = xcb_query_tree_children(tree);

		for(i = 0; i < children; i++)
			if (xcb_config_valid_window(config, window[i]))
				xcb_config_command_wrapper(window[i], .999f);

		free(tree);
	}
}

void xcb_config_set_atom(xcb_config_t* config, char const* atom)
{
	xcb_atom_list_t* list;
	xcb_atom_list_t* iterator;
	xcb_intern_atom_reply_t* reply;

	list = (xcb_atom_list_t*)malloc(sizeof(xcb_atom_list_t));

	list->cookie =
		xcb_intern_atom_unchecked(config->connection, 1, strlen(atom), atom);
	reply = xcb_intern_atom_reply(config->connection, list->cookie, NULL);

	if (reply)
	{
		list->atom = reply->atom;
		list->next = config->list;
		config->list = list;

		xcb_get_property_cookie_t cookie_property =
			xcb_get_property_unchecked(config->connection, 0,
				config->screen->root, list->atom,
				XCB_ATOM_WINDOW, 0, UINT32_MAX);
		xcb_get_property_reply_t* reply_property =
			xcb_get_property_reply(config->connection, cookie_property, NULL);

		if (reply_property)
		{
			xcb_window_t* window = xcb_get_property_value(reply_property);

			config->window = *window;

			free(reply_property);
		}

		free(reply);
	}
	else
		free(list);
}

void xcb_config_set_error(xcb_config_t* config, int error)
{
	config->error = error;
}

void xcb_config_set_event_mask(xcb_config_t* config,
	uint16_t mask, uint32_t* values)
{
	xcb_change_window_attributes(config->connection,
		config->screen->root, mask, values);
}

void xcb_config_event_loop(xcb_config_t* config)
{
	int done = 0;

	xcb_generic_event_t* event;

	while(event = xcb_wait_for_event(config->connection))
	{
		if (xcb_connection_has_error(config->connection))
			break;

		switch(event->response_type & XCB_EVENT_RESPONSE_TYPE_MASK)
		{
			case XCB_PROPERTY_NOTIFY:
				done = xcb_config_event_property_notify(config, event);
				break;
			default:
				break;
		}

		free(event);
		event = NULL;

		if (done)
			break;
	}

	if (event)
		free(event);
}

int  xcb_config_event_property_notify(xcb_config_t* config,
	xcb_generic_event_t* event)
{
	xcb_atom_list_t* list;

	xcb_property_notify_event_t const* property = 
		(xcb_property_notify_event_t const*)event;

	if (property->window == XCB_WINDOW_NONE)
		return 1;

	for(list = config->list; list; list = list->next)
	{
		if (property->atom == list->atom)
		{
			xcb_config_event_property_update(config);

			break;
		}
	}

	return 0;
}

void xcb_config_event_property_update(xcb_config_t* config)
{
	float opacity;

	xcb_config_ignore_list_t* ignore;

	xcb_get_input_focus_cookie_t cookie =
		xcb_get_input_focus_unchecked(config->connection);
	xcb_get_input_focus_reply_t* reply =
		xcb_get_input_focus_reply(config->connection, cookie, NULL);

	if (reply)
	{
		xcb_get_property_cookie_t cookie_wm_class =
			xcb_icccm_get_wm_class_unchecked(config->connection, reply->focus);
		xcb_icccm_get_wm_class_reply_t reply_wm_class;

		if (xcb_icccm_get_wm_class_reply(config->connection,
				cookie_wm_class, &reply_wm_class, NULL))
			xcb_icccm_get_wm_class_reply_wipe(&reply_wm_class);
		else
			/* focus is set to a child window */
			xcb_config_find_parent(config, &reply->focus);

		cookie_wm_class =
			xcb_icccm_get_wm_class_unchecked(config->connection,
				config->window);

		if (xcb_icccm_get_wm_class_reply(config->connection,
				cookie_wm_class, &reply_wm_class, NULL))
		{
			/* root window was activei: set focused window opaque */
			if (strlen(reply_wm_class.class_name) == 0)
				config->window = reply->focus;
			else
			{
				for(ignore = config->ignore; ignore; ignore = ignore->next)
				{
					if (strncmp(ignore->name, reply_wm_class.class_name,
						ignore->length) == 0)
					{
						config->window = reply->focus;

						break;
					}
				}
			}

			xcb_icccm_get_wm_class_reply_wipe(&reply_wm_class);
		}

		if (xcb_config_valid_window(config, config->window))
		{
			opacity = .999f;
			if (config->window != reply->focus)
				opacity = config->opacity;

			xcb_config_command_wrapper(config->window, opacity);
		}
		/* window was closed */
		else if (xcb_config_valid_window(config, reply->focus))
			xcb_config_command_wrapper(reply->focus, .999f);

		config->window = reply->focus;

		free(reply);
	}
}

void register_signal_handlers()
{
	signal(SIGKILL, signal_handler);
	signal(SIGTERM, signal_handler);
}

void signal_handler(int signal)
{
	xcb_connection_t* connection;
	xcb_window_t window;

	if (global)
	{
		connection = global->connection;
		window = global->screen->root;
		global = NULL;

		xcb_property_notify_event_t* event = (xcb_property_notify_event_t*)
			malloc(sizeof(xcb_property_notify_event_t));
		memset(event, 0, sizeof(xcb_property_notify_event_t));

		event->response_type = XCB_PROPERTY_NOTIFY;

		xcb_send_event(connection, 0, window,
			XCB_EVENT_MASK_PROPERTY_CHANGE, (char const*)event);
		xcb_flush(connection);
	}
}

