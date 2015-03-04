#!/usr/bin/env python
# -*- coding: utf-8 -*-

#################################################################################
#																				#
# Автор:	Косьмина Ярослав													#
# Сайт:		http://darviarush.narod.ru											#
#																				#
# Среда:	http://php.net														#
#																				#
#################################################################################

# локаль
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import traceback

ref = None

import json, codecs, re


def frisky_kitty(req, *v, **kv):
	r = [chr(6), req]
	if len(kv): v.append(kv)
	if len(v): r.append(' '); r.append(json.dumps(v))
	print "".join(r)
	sys.stdout.flush()
	
def kitty(req, *v, **kv):
	frisky_kitty(chr(6)+req, *v, **kv)
	line = sys.stdin.readline()
	if line[0]=='{' or line[0]=='[': line = json.loads(line)
	return line

actions = {}

request = sys.stdin.readline()

while request != '':
	request = request.rstrip()
	
	action = actions.get(request)
	if not action:
		action = 'kitty_' + re.sub(r'[/.-]', '__', request)
	
		file = codecs.open(request, 'rb', 'utf8').read()
		file = re.sub(r'^', '\t', file, 0, re.M)
		file = ''.join(["def ", action, "():\n", file])
		glob = {"frisky_kitty": frisky_kitty, "kitty": kitty}
		loc = {}
		exec( file, glob, loc )
		
		actions[request] = action = loc[action]

	try:
		ref = action()
	except BaseException as e:
		sys.stderr.write( traceback.format_exc() )

	request = kitty("end", ref)
	ref = None

