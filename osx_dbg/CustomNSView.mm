//

#import <AppKit/NSScreen.h>
#import <CoreVideo/CVDisplayLink.h>
#import <AppKit/NSApplication.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/MTLDevice.h>
#import <math.h>

#include <QuartzCore/CAMetalLayer.hpp>
#include <Metal/MTLDevice.hpp>

#import "types.h"
#import "CustomNSView.h"
#import "osx_renderer.h"
#import "osx_profiler.h"

static CVDisplayLinkRef displayLink;
static CAMetalLayer *layer;

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
  logMemory();
  CVReturn error = [(__bridge CustomNSView *) displayLinkContext displayFrame:inOutputTime];
  return error;
}

- (CVReturn)displayFrame:(const CVTimeStamp *)inOutputTime {
  render((__bridge CA::MetalLayer *) layer);
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self setNeedsDisplay:YES];
  });
  return kCVReturnSuccess;
}

- (void)awakeFromNib
{
  layer = [CAMetalLayer layer];
  layer.device = MTLCreateSystemDefaultDevice();
  self.layer = layer;
  self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
  initRenderer((__bridge MTL::Device *) layer.device);
  
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
