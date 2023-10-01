#ifndef osx_profiler_h
#define osx_profiler_h

#include <CoreVideo/CVDisplayLink.h>

void logFrameTime(const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime);
void logMemory();

#endif
