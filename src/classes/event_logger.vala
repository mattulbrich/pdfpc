/**
 * Presentation Event controller
 *
 * This file is part of pdfpc.
 *
 * Copyright (C) 2010-2011 Jakob Westhoff <jakob@westhoffswelt.de>
 * Copyright 2010 Joachim Breitner
 * Copyright 2011, 2012 David Vilar
 * Copyright 2012 Matthias Larisch
 * Copyright 2012, 2015 Robert Schroll
 * Copyright 2012 Thomas Tschager
 * Copyright 2015,2017 Andreas Bilke
 * Copyright 2015 Andy Barry
 * Copyright 2017 Olivier Pantalé
 * Copyright 2017 Philipp Berndt
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

using Gee;

namespace pdfpc {
    /**
     * Controller handling all the triggered events/signals
     */
    public class EventLogger : Object {

        private int64 startTime = 0;

        private int lastSlide = -1;

        private int64 lastPointerMovement = 0;
        
        private static int64 now() {
            return GLib.get_real_time () / 1000;
        }

        public bool isActive() {
          return log_file() != null;
        }

        private Gee.List<string> history = new ArrayList<string> ();

        public string? log_file() {
          return Options.event_log_file;
        }
        
        private void add_event(string command, string args) {
            if(isActive()) {
                if(startTime == 0) {
                    startTime = now();
                }
                int64 time = now() - startTime;
                history.add(@"{ \"stamp\":$time, \"cmd\": \"$command\", $args }");
            }
        }

        public void add_slide_change(int newSlide) {
            if(lastSlide == newSlide) {
                return;
            }
            add_event("slide", @"\"no\": $newSlide");
            lastSlide = newSlide;
        }

        public void add_pointer_movement(double x, double y) {
            var t = now();
            if(t - lastPointerMovement > 200) {
                add_event("move", @"\"x\": $x, \"y\": $y");
                lastPointerMovement = t;
            }
        }

        public void add_mode_change(string mode) {
            add_event("mode", @"\"mode\": \"$mode\"");
        }

        public void quit() {
            try {

                if(!isActive()) {
                    return;
                }
                
                // an output file in the current working directory
                var file = File.new_for_path (log_file());

                // delete if file already exists
                if (file.query_exists ()) {
                    file.delete ();
                }

                // creating a file and a DataOutputStream to the file
                var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));

                dos.put_string("[ ");
                // writing a short string to the stream
                bool first = true;
                foreach(string line in history) {
                    if (first) {
                        first = false;
                    } else {
                        dos.put_string(",\n");
                    }
                    dos.put_string(line);
                }
                dos.put_string("]\n");
        
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
                return;
            }
        }
    }        

}
