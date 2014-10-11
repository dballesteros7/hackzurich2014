#ifndef EVERNOTE_WRAPPER_INCLUDED
#define EVERNOTE_WRAPPER_INCLUDED
#ifdef __cplusplus
extern "C" {
#endif
    const char * getNotes(void);
    void makeNote(const char *imagePath);
#ifdef __cplusplus
}
#endif
#endif
