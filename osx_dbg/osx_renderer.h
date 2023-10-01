//
#ifndef osx_renderer_h
#define osx_renderer_h

#include <QuartzCore/CAMetalLayer.hpp>
#include <Metal/MTLDevice.hpp>

void initRenderer(MTL::Device *device);
void render(CA::MetalLayer *layer);

#endif
