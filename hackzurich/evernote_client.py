import binascii
import hashlib
import xml.etree.ElementTree as ET

from evernote.api.client import EvernoteClient
from evernote.edam.notestore.ttypes import NoteFilter, NotesMetadataResultSpec
from evernote.edam.type.ttypes import Notebook, Note, Data, Resource,\
    ResourceAttributes
from evernote.edam.error.ttypes import EDAMUserException, EDAMNotFoundException

client = None


def retrieve_note_content():
    global client
    if client is None:
        client = HackzurichEvernoteClient()
    note_content = client.retrieve_note_content()
    root = ET.fromstring(note_content)
    return root.text


def make_note(file_path):
    global client
    if client is None:
        client = HackzurichEvernoteClient()
    with open(file_path, 'rb') as f:
        full_image = f.read()
        client.make_note_with_image(full_image)


class HackzurichEvernoteClient(object):

    DEFAULT_NOTEBOOK_NAME = 'hackzurich 2014'

    NOTE_WITH_IMAGE = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>{}
<br/>
<br/>
Attachment with hash {}: <br/>
<en-media type="{}" hash="{}"/><br/>
</en-note>
    """

    def __init__(self):
        self._dev_token = 'S=s1:U=8fa4c:E=1505408518e:C=148fc572290:P=1cd:A=en-devtoken:V=2:H=971b5b78f110bdc8cd1579f3e0f5e6cb'
        self._evernote_client = EvernoteClient(token=self._dev_token)
        self._user_store = self._evernote_client.get_user_store()
        self._note_store = self._evernote_client.get_note_store()

        self._default_notebook_guid = None

    def get_notebook_guid(self):
        if self._default_notebook_guid is not None:
            return self._default_notebook_guid
        for notebook in self._note_store.listNotebooks():
            if notebook.name == HackzurichEvernoteClient.DEFAULT_NOTEBOOK_NAME:
                self._default_notebook_guid = notebook.guid
                return notebook.guid

    def create_default_notebook(self):
        notebook = Notebook(
            name=HackzurichEvernoteClient.DEFAULT_NOTEBOOK_NAME)
        self._note_store.createNotebook(notebook)
        self._default_notebook_guid = notebook.guid
        return self.get_notebook_guid()

    def retrieve_note(self):
        note_filter = NoteFilter(
            order=2, notebookGuid=self.get_notebook_guid())
        result_spec = NotesMetadataResultSpec(
            includeTitle=True)
        notesMetadata = self._note_store.findNotesMetadata(
            note_filter, 0, 1, result_spec)
        if notesMetadata.notes:
            note_guid = notesMetadata.notes[0].guid
            retrieved_note = self._note_store.getNote(
                note_guid, False,
                False,
                True,
                False)
            for resource in retrieved_note.resources:
                print resource

    def retrieve_note_content(self):
        note_filter = NoteFilter(
            order=2, notebookGuid=self.get_notebook_guid())
        result_spec = NotesMetadataResultSpec(
            includeTitle=True)
        notesMetadata = self._note_store.findNotesMetadata(
            note_filter, 0, 1, result_spec)
        if notesMetadata.notes:
            note_guid = notesMetadata.notes[0].guid
            return self._note_store.getNoteContent(note_guid)
        return 'ERROR: There are no notes in the notebook.'

    def store_note(self, note_title, note_content):
        notebook_guid = self.get_notebook_guid()
        if notebook_guid is None:
            notebook_guid = self.create_default_notebook()
        note = Note()
        note.title = note_title
        note.content = HackzurichEvernoteClient.NOTE_BOILERPLATE.format(
            note_content)
        note.notebookGuid = notebook_guid
        self._note_store.createNote(note)
        return note.guid

    def make_note_with_image(self, image_string):

        note = Note()
        note.title = 'Note created with ...'

        data = Data()
        data.body = image_string
        hash_md5 = hashlib.md5()
        hash_md5.update(data.body)
        data.bodyHash = hash_md5.digest()
        data.size = len(image_string)
        resource = Resource()
        resource.data = data
        resource.mime = 'image/jpeg'
        resource.width = 4160
        resource.height = 3120
        resource_attr = ResourceAttributes()
        resource_attr.attachment = False
        resource.attributes = resource_attr
        note.resources = [resource]

        hexhash = binascii.hexlify(resource.data.bodyHash)
        note.content = HackzurichEvernoteClient.NOTE_WITH_IMAGE.format(
            '', hexhash, 'image/jpeg', hexhash)

        note.notebookGuid = self.get_notebook_guid()

        try:
            created_note = self._note_store.createNote(note)
        except EDAMUserException as edue:
            print "EDAMUserException:", edue
            return None
        except EDAMNotFoundException:
            print "EDAMNotFoundException: Invalid parent notebook GUID"
            return None
        return created_note


# with open('/home/diegob/Pictures/ocr-2.jpg', 'rb') as f:
#     full_image = f.read()
#     client = HackzurichEvernoteClient()
#     client.make_note_with_image(full_image)
#     client.retrieve_note()
