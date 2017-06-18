#!/usr/bin/env python
# -*- coding: utf8 -*-

import os, re, sqlite3
from bs4 import BeautifulSoup, NavigableString, Tag

conn = sqlite3.connect('bitbake.docset/Contents/Resources/docSet.dsidx')
cur = conn.cursor()

try: cur.execute('DROP TABLE searchIndex;')
except: pass
cur.execute('CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);')
cur.execute('CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);')

docpath = 'bitbake.docset/Contents/Resources/Documents'

page = open(os.path.join(docpath, 'bitbake-user-manual.html')).read()
soup = BeautifulSoup(page, "html.parser")

def insert_type(db, title, type, path):
    db.execute('INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?,?,?)', (title, type, path))
    print 'title: %s, type: %s, path: %s' % (title, type, path)

def insert_variable(db, title, path):
    insert_type(db, title, 'Variable', path)

def insert_section(db, title, path):
    insert_type(db, title, 'Section', path)

def is_variable(id):
    return id and re.compile("var-\w+").search(id)

def create_variables():
    for tag in soup.find_all(id=is_variable):
        title = tag.parent.contents[1]
        href = tag.attrs['id']
        path = "bitbake.htm#%s" % href
        insert_variable(cur, title, path)

def create_chapters():
    for tag in soup.find_all('div', {'class': 'chapter'}):
        r = re.compile(r"Chapter\s\d\.\s(?P<title>.*)", re.UNICODE)
        t = tag.attrs['title'].strip()
        m = r.match(t)
        title = m.group('title')
        href = tag.div.div.a.get('id').strip()
        path = "bitbake.htm#%s" % href
        insert_section(cur, title, path)

def create_sections():
    for tag in soup.find_all('div', {'class': 'section'}):
        r = re.compile(r"([\w\d]\.?)+\s(?P<title>.*)", re.UNICODE)
        t = tag.attrs['title'].strip()
        m = r.match(t)
        title = m.group('title')
        href = tag.div.div.a.get('id').strip()
        path = "bitbake.htm#%s" % href
        insert_section(cur, title, path)

create_variables()
create_chapters()
create_sections()

conn.commit()
conn.close()