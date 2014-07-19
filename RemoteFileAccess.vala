/***
  Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see <http://www.gnu.org/licenses>
***/

using Granite;
using Gtk;

namespace Shift {

    class RemoteFileAccess : IFileAccess, GLib.Object {

        private IConnInfo connect_info;
        private File file_handle;

        public async bool connect_to_device (IConnInfo connect_info) {
            var mount = mount_operation_from_connect (connect_info);
            var uri = connect_info.get_uri ();
            file_handle = File.new_for_uri (uri);
            try {
                return yield file_handle.mount_enclosing_volume (MountMountFlags.NONE, mount, null);
            } catch (Error e) {
                // Already mounted
                if (e.code == 17) {
                    return true;
                } else {
                    stdout.printf ("ERROR MOUNTING: " + e.message + "\n");
                    return false;
                }
            } finally {
                connected ();
            }
        }

        public async List<FileInfo> get_file_list (string path) {
            try {
                stdout.printf ("Test test test\n");
                var file_enum = yield file_handle.enumerate_children_async (
                        "standard::*", 0, Priority.DEFAULT);
                return yield file_enum.next_files_async (5000, Priority.DEFAULT);
            } catch (Error e) {
                stderr.printf ("File list error: %s %d\n", e.message, e.code);
                // Unmounted
                if (e.code == 16) {
                    //
                }
                // Host closed conn
                if (e.code == 0) {
                }
            }
            return new List<FileInfo>();
        }

        public string get_path () {
            return file_handle.resolve_relative_path ("/").get_relative_path (file_handle);
        }

        public void goto_parent () {
        }

        public void goto_child (string name) {
            file_handle = file_handle.get_child (name);
        }

        public void goto_path (string path) {
            file_handle = file_handle.resolve_relative_path ("/" + path);
        }

        private Gtk.MountOperation mount_operation_from_connect (IConnInfo connect_info) {
            var mount = new Gtk.MountOperation (new Gtk.Window ());
            mount.set_domain (connect_info.hostname);
            stdout.printf ("MOUNT HOST: " + connect_info.hostname + "\n");
            mount.set_anonymous (connect_info.anonymous);
            mount.set_password_save (PasswordSave.FOR_SESSION);
            mount.set_choice (0);
            if (!connect_info.anonymous) {
                stdout.printf ("Got here\n");
                mount.set_username (connect_info.username);
                mount.set_password (connect_info.password);
            }
            mount.ask_password.connect ((message, user, domain, flags) => {
                stdout.printf ("ENTER PASSWORD %s %s\n", message, domain);
                mount.set_password (connect_info.password);
            });
            return mount;
        }
    }
}