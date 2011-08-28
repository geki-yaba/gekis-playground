/*
 *         Author: Hanno Meyer-Thurow <h.mth@web.de>
 *
 *        Purpose: Set opacity for all windows.
 *                 The focused window is opaque.
 *
 * Contributor(s): None
 *
 * Based on the work of ADcomp <david.madbox@gmail.com> [ http://www.ad-comp.be/ ]
 * with extra bits by Benj1 <holroyd.ben@gmail.com>
 *
 *     http://crunchbanglinux.org/forums/post/33142/#p33142
 *
 * This program is distributed under the terms of the GNU General Public License.
 * For more info see http://www.gnu.org/licenses/gpl.txt.
 */

/*
 * COMPILE
 *
 *     gcc -O2 -march=native -pipe scripts/trans_follow_xcb.c \
 *         -o /usr/local/bin/trans-follow $(pkg-config --libs xcb xcb-icccm)
 */

/*
 * HACKING
 *
 * If you feel like hacking on this code, please follow current coding style.
 * If you see a violation to proper coding styles, please report it to me!
 *
 * Your changes must be stored as a unified diff.
 * The easiest way to do so is to checkout this subversion reposity and do a:
 *
 *     svn diff scripts/trans_follow_xcb.c > changes.diff
 *
 * This is necessary to integrate your work smoothly.
 *
 * Please send your changes with description to my email address above.
 */

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
    float opacity;
    int screen_no;
    xcb_connection_t* connection;
    xcb_screen_t* screen;
    xcb_window_t window;
    xcb_atom_list_t* list;
    xcb_config_ignore_list_t* ignore;
} xcb_config_t;

int  xcb_config_run(int argc, char* argv[]);
void xcb_config_parse(xcb_config_t* config, int argc, char* argv[]);
int  xcb_config_error(xcb_config_t* config);
void xcb_config_command(char const* command);
int  xcb_config_init(xcb_config_t* config);
void xcb_config_uninit(xcb_config_t* config);
void xcb_config_set_atom(xcb_config_t* config, char const* atom);
void xcb_config_set_event_mask(xcb_config_t* config,
    uint16_t mask, uint32_t* values, unsigned int size);
void xcb_config_event_loop(xcb_config_t* config);
void xcb_config_event_property_notify(xcb_config_t* config,
    xcb_generic_event_t* event);
void xcb_config_event_property_update(xcb_config_t* config);

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

    int error = xcb_config_init(&config);

    if (! error)
    {
        xcb_config_parse(&config, argc, argv);

        mask = XCB_CW_EVENT_MASK;
        values[0] = XCB_EVENT_MASK_PROPERTY_CHANGE;

        xcb_config_set_event_mask(&config, mask, values, size);
        xcb_config_set_atom(&config, "_NET_ACTIVE_WINDOW");
        xcb_config_set_atom(&config, "_NET_CURRENT_DESKTOP");

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

        if ((0.0f > opacity) || (opacity > 1.0f))
            opacity = 1.0f;
    }
    else
        opacity = 0.75f;

    config->opacity = opacity;

    if (argc > 2)
    {
        for (i = 2; i < argc; i++)
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

int  xcb_config_init(xcb_config_t* config)
{
    int i;

    config->connection = xcb_connect(NULL, &config->screen_no);
    config->error = xcb_connection_has_error(config->connection);

    config->screen = NULL;
    config->window = 0;
    config->list = NULL;
    config->ignore = NULL;

    if (! xcb_config_error(config))
    {
        xcb_setup_t const* setup = xcb_get_setup(config->connection);
        xcb_screen_iterator_t iterator = xcb_setup_roots_iterator(setup);  

        for (i = 0; i < config->screen_no; i++)
            xcb_screen_next(&iterator);

        config->screen = iterator.data;

        if (! config->screen)
            config->error = 1;
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

    if (config->connection)
        xcb_disconnect(config->connection);
}

void xcb_config_set_atom(xcb_config_t* config, char const* atom)
{
    xcb_atom_list_t* list;
    xcb_atom_list_t* iterator;
    xcb_intern_atom_reply_t* reply;

    list = (xcb_atom_list_t*)malloc(sizeof(xcb_atom_list_t));
    list->next = NULL;

    list->cookie = xcb_intern_atom_unchecked(config->connection, 1, strlen(atom), atom);
    reply = xcb_intern_atom_reply(config->connection, list->cookie, NULL);

    if (reply)
    {
        list->atom = reply->atom;

        iterator = config->list;
	while(iterator && iterator->next)
            iterator = iterator->next;

        if (iterator)
            iterator->next = list;
        else
            config->list = list;

        xcb_get_property_cookie_t cookie_property =
            xcb_get_property_unchecked(config->connection, 0, config->screen->root,
                list->atom, XCB_ATOM_WINDOW, 0, UINT32_MAX);
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

void xcb_config_set_event_mask(xcb_config_t* config,
    uint16_t mask, uint32_t* values, unsigned int size)
{
    xcb_change_window_attributes(config->connection,
        config->screen->root, mask, values);
}

void xcb_config_event_loop(xcb_config_t* config)
{
    xcb_generic_event_t* event;

    while(event = xcb_wait_for_event(config->connection))
    {
        switch(event->response_type & XCB_EVENT_RESPONSE_TYPE_MASK)
        {
            case XCB_PROPERTY_NOTIFY:
                xcb_config_event_property_notify(config, event);
                break;
            default:
                break;
        }

        free(event);
    }
}

void xcb_config_event_property_notify(xcb_config_t* config,
    xcb_generic_event_t* event)
{
    xcb_property_notify_event_t const* property = 
        (xcb_property_notify_event_t const*)event;

    xcb_atom_list_t* list;

    for (list = config->list; list; list = list->next)
        if (property->atom == list->atom)
            xcb_config_event_property_update(config);
}

void xcb_config_event_property_update(xcb_config_t* config)
{
    float opacity;
    char buffer[40];
    int count;

    xcb_config_ignore_list_t* ignore;

    xcb_get_input_focus_cookie_t cookie =
        xcb_get_input_focus_unchecked(config->connection);
    xcb_get_input_focus_reply_t* reply =
        xcb_get_input_focus_reply(config->connection, cookie, NULL);

    if (reply)
    {
        xcb_get_property_cookie_t cookie_wm_class =
            xcb_icccm_get_wm_class_unchecked(config->connection, config->window);
        xcb_icccm_get_wm_class_reply_t reply_wm_class;

        if (xcb_icccm_get_wm_class_reply(config->connection,
                cookie_wm_class, &reply_wm_class, NULL))
        {
            /* workaround: desktop window was active
             *             set focused window opaque
             */
            if (strlen(reply_wm_class.class_name) == 0)
                config->window = reply->focus;
            else
            {
                for (ignore = config->ignore; ignore; ignore = ignore->next)
                {
                    if (strncmp(ignore->name, reply_wm_class.class_name, ignore->length) == 0)
                    {
                        config->window = reply->focus;

                        break;
                    }
                }
            }

            xcb_icccm_get_wm_class_reply_wipe(&reply_wm_class);
        }

        opacity = 1.0f;
        if (config->window != reply->focus)
            opacity = config->opacity;

        count = sprintf(buffer, "transset-df -i 0x%x %1.3f",
            config->window, opacity);

        buffer[count] = '\0';

        xcb_config_command(buffer);

        config->window = reply->focus;

        free(reply);
    }
}

