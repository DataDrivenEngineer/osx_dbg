//

#import <AppKit/NSScreen.h>
#import <CoreVideo/CVDisplayLink.h>
#import <AppKit/NSApplication.h>
#import <QuartzCore/CAMetalLayer.h>
#import <mach/mach_time.h>
#import <math.h>

#import "types.h"
#import "CustomNSView.h"

static struct mach_timebase_info mti;
static CVDisplayLinkRef displayLink;
static CAMetalLayer *layer;

static void initTimebaseInfo(void)
{
  kern_return_t result;
  if ((result = mach_timebase_info(&mti)) != KERN_SUCCESS) printf("Failed to initialize timebase info. Error code: %d", result);
}

static void logFrameTime(const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime)
{
  static u64 previousNowNs = 0;
  u64 currentNowNs = inNow->hostTime * mti.numer / mti.denom;
  u64 inNowDiff = currentNowNs - previousNowNs;
  previousNowNs = currentNowNs;
  // Divide by 1000000 to convert from ns to ms
  fprintf(stderr, "inNow frame time: %f ms\n", (r32) inNowDiff / 1000000);

  u64 processingWindowNs = (inOutputTime->hostTime - inNow->hostTime) * mti.numer / mti.denom;
  fprintf(stderr, "processingWindow: %f ms\n", (r32) processingWindowNs / 1000000);
}

void resumeDisplayLink(void)
{
  if (!CVDisplayLinkIsRunning(displayLink)) {
    CVDisplayLinkStart(displayLink);
  }
}

void stopDisplayLink(void)
{
  if (CVDisplayLinkIsRunning(displayLink)) {
    CVDisplayLinkStop(displayLink);
  }
}

@implementation CustomNSView

static CVReturn renderCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
  logFrameTime(inNow, inOutputTime);
  CVReturn error = [(__bridge CustomNSView *) displayLinkContext displayFrame:inOutputTime];
  return error;
}

- (CVReturn)displayFrame:(const CVTimeStamp *)inOutputTime {
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self setNeedsDisplay:YES];
  });
  return kCVReturnSuccess;
}

- (void)awakeFromNib
{
  layer = [CAMetalLayer layer];
  self.wantsLayer = YES;
  self.layer = layer;
  self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
  
  CGDirectDisplayID displayID = CGMainDisplayID();
  CVReturn error = kCVReturnSuccess;
  error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);
  if (error)
  {
    fprintf(stderr, "DisplayLink created with error:%d\n", error);
    displayLink = 0;
  }
  CVDisplayLinkSetOutputCallback(displayLink, renderCallback, (__bridge void *)self);
  CVDisplayLinkStart(displayLink);
  
  initTimebaseInfo();
}

- (void) dealloc
{
  [super dealloc];
  stopDisplayLink();
  CVDisplayLinkRelease(displayLink);
}

- (BOOL) wantsUpdateLayer
{
  return YES;
}

- (void)updateLayer
{
  fprintf(stderr, "updateLayer - never called!\n");
}

@end
