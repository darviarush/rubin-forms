#!/usr/bin/env python
#-*- coding: utf-8 -*-

import unittest, os, re
from mishel import Mishel, Messenger

class MockMessenger(Messenger):
	""" заглушка для общения """
		
	def __init__(self, *av, **kv):
		""" конструктор """
		self._reply = []
		super(type(self), self).__init__(*av, **kv)
		
	def message(self, msg, from_id):
		""" получает сообщение """
		print "<< %s" % msg
		
		self.onmessage(msg, from_id)
		
	def say(self, msg, to):
		""" отправляет сообщение списку реципиентов """
		print ">> %s" % msg
		self._reply.append(msg)
	
	def _last(self):
		""" возвращает последнее сообщение """
		assert len(self._reply) == 1, u"не одно сообщение"
		msg = self._reply.pop()
		return msg
		


class TestMishel(unittest.TestCase):
	""" проверяем Мишель """

	def setUp(self):
		""" setup """
		
		save_path = "mishel-test.json"
		if os.path.exists(save_path):
			os.remove(save_path)
		
		self.from_id = "maximus@august.com"
		self.messenger = MockMessenger(self.from_id, "***")
		self.mishel = Mishel(self.messenger, [self.from_id], save_path)
		
		self
	
	def test_commands(self):
		""" проверяем срабатывание на команды """
		
		id = self.from_id
		messenger = self.messenger
		
		self.mishel.task()
		
		messenger.message("?", id)
		self.assertRegexpMatches( messenger._last(), ur"1\.", "нет списка команд" )
		
		messenger.message("покажи задания", id)
		self.assertEqual( messenger._last(), u"заданий пока нет" )
		
		messenger.message("добавь: задание №1\nчто-то", id)
		self.assertIn( "добавила", messenger._last(), "не добавлено")
		
		messenger.message("покажи задания", id)
		msg = messenger._last()
		self.assertIn( "задание №1", msg, "не показаны задания" )
		self.assertNotIn( "что-то", msg, "показывается тело задания" )
		
		self.mishel.task()
		self.assertIn("задание №1", messenger._last(), "сработала задача")
		self.mishel.task()
		self.assertIn("задание №1", messenger._last(), "сработала задача 2-й раз")
		
		messenger.message("удали 1", id)
		self.assertIn("удалила", messenger._last(), "не удалено")
		
		messenger.message("покажи задания", id)
		self.assertEqual( messenger._last(), u"заданий пока нет" )
		

if __name__ == '__main__':
    unittest.main()
