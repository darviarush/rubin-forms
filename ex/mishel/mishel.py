#!/usr/bin/env python
#-*- coding: utf-8 -*-

import sys
reload(sys)
sys.setdefaultencoding('utf8')

import xmpp, atexit, json, codecs, re
import os.path
import schedule




class Messenger:
	""" для общения """

	def __init__(self, login, password, onmessage=None):
		""" конструктор """
		self.login = login
		self.password = password
		self.onmessage = onmessage
		self
		
	def connect(self):
		""" коннектится """
		self
		
	def message(self, msg, from_id):
		""" получает сообщение """
		self.onmessage(msg, from_id)
		
	def say(self, msg, to_id):
		""" отправляет сообщение списку реципиентов """
		self
		
	def run_once(self):
		""" шаг """
		self
	
	def disconnect(self):
		""" отключаемся """
		self
		
		
class JabberMessenger(Messenger):
	""" общение через джаббер """
	
	
	def connect(self):
		""" коннектится """
		jid = xmpp.protocol.JID(self.login)
		self.jabber = jabber = xmpp.Client(jid.getDomain(), debug=[])
		jabber.connect(secure=0)
		jabber.auth(jid.getNode(), str(self.password), resource='xmpppy')

		# регистрируем обработчики
		def onmessage(jabber, msg):
			#print 'message_callback', msg.getType(), msg.getID(), msg.getFrom(), msg.getThread(), msg.getSubject(), msg.getBody(), repr(msg.getProperties())
			s = msg.getBody()
			if not s:
				return
			
			jid = msg.getFrom()
			from_id = "%s@%s" % (jid.getNode(), jid.getDomain())
			self.message(s, from_id)
			return
			
		jabber.RegisterHandler('message', onmessage)
		
		jabber.sendInitPresence()

		#print jabber.connected
		#assert jabber.connected, "приконнектился"

	def say(self, msg, to):
		""" отправляет сообщение списку реципиентов """
		msg += u""
		for jid in to:
			self.jabber.send(xmpp.protocol.Message(jid, msg))
		
	def run_once(self):
		""" шаг """
		self.jabber.Process(1)
		
	def disconnect(self):
		""" отключаемся """
		self.jabber.disconnect()
		
		

class Mishel:
	""" Мишель """

	def __init__(self, messenger, id_masters, save_path):
		''' конструктор '''
		self.messenger = messenger
		messenger.onmessage = lambda msg, to_id: self.message(msg, to_id)
		
		assert isinstance(id_masters, list), u"требуется список мастеров"
		assert len(id_masters)>0, u"список мастеров не должен быть пустым"
		self.id_masters = id_masters
		
		assert save_path, u"не указан путь к ini-файлу json"
		self.save_path = save_path
		self.load()
		
	def load(self):
		""" загружает данные """
		save_path = self.save_path
		if os.path.isfile(save_path) and os.path.getsize(save_path) != 0:
			with codecs.open(save_path, "rb", encoding='utf8') as f:
				self.ion = json.load(f)
		else:
			self.ion = {
				'tz': [],		# задания
				'idx': 0,		# номер задания
			}

	def save(self):
		''' выполняется при завершении и сохраняет данные '''
		with codecs.open(self.save_path, "wb", encoding='utf8') as f:
			json.dump(self.ion, f)
			
	def message(self, msg, from_id):
		''' пришло сообщение '''
		msg += u""
	
		if from_id not in self.id_masters:
			self.say(u"Написал %s: %s" % (from_id, msg))
			return self
		#jabber.send(xmpp.protocol.Message(from_id, u"вау! приветики! ты сказал: %s" % s))
		
		tail = [""]
		def test(m):
			m = re.sub(ur'\s+', ur'\s+', m)
			#print m, type(m)
			g = re.match(ur"\s*%s[ \t]*" % m, msg)
			#print g
			if not g:
				return False
			tail[0] = msg[g.end():]
			
			return True
		
		if test(r"список команд|\?"):
			self.say(u"1. список команд или ?\n"+
				u"2. добавь: <задание>\n"+
				u"3. замени <номер задания>: <задание>\n"+
				u"4. удали <номер задания>\n"+
				u"5. покажи задания\n"
			)
		elif test("добавь:"):
			tz = self.ion["tz"]
			if None in tz:
				idx = tz.index(None)
				tz[idx] = tail[0]
			else:
				idx = len(tz)
				tz.append(tail[0])
				
			self.say("добавила. № %i" % (idx+1))
			self.save()
		elif test("замени"):
			try:
				idx, x = tail[0].split(":")
				tz[int(idx)] = x.lstrip()
			except:
				self.say("не могу :(")
				return
			self.say("заменила")
			self.save()
		elif test("удали"):
			tz = self.ion["tz"]
			try:
				idx = abs(int(tail[0]))
				idx -= 1
				val = tz[idx]
			except:
				val = None
			if val is None:
				self.say("а номер задания какой?")
				return self
			if idx+1 == len(tz):
				tz.pop()
				while len(tz) and tz[-1] is None:
					tz.pop()
			else:
				tz[idx] = None
			self.say("удалила")
			self.save()
		elif test("покажи задания"):
			# берём первую строку каждого задания
			tz = self.ion["tz"]
			if len(tz) == 0:
				self.say("заданий пока нет")
				return self
			
			ls = []
			for i, x in enumerate(tz):
				if not x is None:
					first_line = re.match(ur".*", x).group(0)
					ls.append(u"%i. %s" % (i+1, first_line))
			
			self.say("\n".join(ls))
		else:
			self.say("не понимаю")
		
	
	def say(self, msg, to=None):
		""" отправляет сообщение """
		if to is None:
			to = self.id_masters
		self.messenger.say(msg, to)
		
		
	def task(self):
		""" выдаёт сообщение о задании """
		tz = self.ion["tz"]
		if len(tz)==0:
			return self
		
		idx = self.ion["idx"]
		
		if idx >= len(tz):
			self.ion["idx"] = idx = 0
		else:
			self.ion["idx"]+=1
		s = tz[idx]
		first_line = re.match(ur".*", s).group(0)
		self.say("переключайся на задачу № %i: %s\n" % (idx+1, first_line))


if __name__ == '__main__':

	save_path = 'mishel.json'
	xmpp_jid = 'mishel@jabber.ru'
	xmpp_pwd = 'detiOkeana12'

	xmpp_to = ['halfdroy@gmail.com']
	#msg = 'Привет!'

	
	messenger = JabberMessenger(xmpp_jid, xmpp_pwd)
	mishel = Mishel(messenger, xmpp_to, save_path)
	messenger.connect()


	@atexit.register
	def destroy():
		''' на выход из программы '''
		#mishel.save()
		print "disconnect"
		messenger.disconnect()

		

	for i in xrange(0, 45, 5):
		schedule.every().hour.at("00:%i" % i).do(lambda: mishel.task())

	mishel.task()
			
	# https://github.com/dbader/schedule
	# schedule.every(10).minutes.do(job)
	# schedule.every().hour.do(job)
	# schedule.every().day.at("10:30").do(job)

	

	print "start"

	# бесконечный цикл
	while 1:
		schedule.run_pending()
		messenger.run_once()

