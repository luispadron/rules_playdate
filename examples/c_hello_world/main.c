#include <stdio.h>
#include <stdlib.h>

#include "cplaydate.h"

void InitializeGame(PlaydateAPI* pd);
static int Update(void* pdvoid);
int eventHandler(PlaydateAPI* pd, PDSystemEvent event, uint32_t arg);

int eventHandler(PlaydateAPI* pd, PDSystemEvent event, uint32_t arg) {
  if (event == kEventInit) {
    InitializeGame(pd);
  }

  return 0;
}

void InitializeGame(PlaydateAPI* pd) {
  pd->system->setUpdateCallback(Update, pd);
}

static int Update(void* pdvoid) {
  PlaydateAPI* pd = pdvoid;
  pd->graphics->drawText("Hello World!", strlen("Hello World!"), kASCIIEncoding, 100, 100);
  return 1;
}
