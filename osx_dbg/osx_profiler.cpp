#include <mach/mach_time.h>
#include <mach/vm_statistics.h>
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/mach_host.h>

#include "osx_profiler.h"
#include "types.h"

static u8 mtiInitialized = 0;
static struct mach_timebase_info mti;

static u8 memProfInitialized = 0;
static vm_size_t pageSize;
static mach_port_t port;
static mach_msg_type_number_t count;
static vm_statistics64_data_t vmStats;

static void initMemProf()
{
  port = mach_host_self();
  count = sizeof(vmStats) / sizeof(natural_t);
  if (kern_return_t res = host_page_size(port, &pageSize) != KERN_SUCCESS)
  {
    fprintf(stderr, "Failed to initialize memory profiler, error code: %d\n", res);
  }
}

void logMemory()
{
  if (!memProfInitialized)
  {
    initMemProf();
    memProfInitialized = 1;
  }
  if (KERN_SUCCESS == host_statistics64(port, HOST_VM_INFO, (host_info64_t) &vmStats, &count))
  {
    u64 freeMem = (u64) vmStats.free_count * (u64) pageSize;
    u64 usedMem = ((u64) vmStats.active_count + (u64) vmStats.inactive_count + (u64) vmStats.wire_count) * (u64) pageSize;
    fprintf(stderr, "freeMem (MB): %f, usedMem (MB): %f\n", freeMem / 1024 / 1024 / 1024.f, usedMem / 1024 / 1024 / 1024.f);
  }
}

static void initTimebaseInfo()
{
  kern_return_t result;
  if ((result = mach_timebase_info(&mti)) != KERN_SUCCESS) fprintf(stderr, "Failed to initialize timebase info. Error code: %d", result);
}

void logFrameTime(const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime)
{
  if (!mtiInitialized)
  {
    initTimebaseInfo();
    mtiInitialized = 1;
  }
  static u64 previousNowNs = 0;
  u64 currentNowNs = inNow->hostTime * mti.numer / mti.denom;
  u64 inNowDiff = currentNowNs - previousNowNs;
  previousNowNs = currentNowNs;
  // Divide by 1000000 to convert from ns to ms
  fprintf(stderr, "inNow frame time: %f ms; ", (r32) inNowDiff / 1000000);

  u64 processingWindowNs = (inOutputTime->hostTime - inNow->hostTime) * mti.numer / mti.denom;
  fprintf(stderr, "processingWindow: %f ms\n", (r32) processingWindowNs / 1000000);
}
