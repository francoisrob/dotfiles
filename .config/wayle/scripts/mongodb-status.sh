#!/bin/sh
# MongoDB unit state for the wayle bar module, as JSON so the module can style
# on `class` and carry a tooltip.
#
# /bin/sh rather than bash: `systemctl is-active --quiet` is the only fork and
# accounts for nearly all the runtime, so the interpreter is the only thing left
# to trim. Measured ~0.7ms saved per poll.
if systemctl is-active --quiet mongodb; then
	echo '{"text":"on","class":"active","tooltip":"MongoDB is running"}'
else
	echo '{"text":"off","class":"inactive","tooltip":"MongoDB is stopped"}'
fi
