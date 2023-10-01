//
#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION

#include "osx_renderer.h"

#include <Foundation/NSAutoreleasePool.hpp>
#include <Metal/MTLCommandQueue.hpp>
#include <Metal/MTLCommandBuffer.hpp>
#include <Metal/MTLRenderCommandEncoder.hpp>
#include <Metal/MTLRenderPass.hpp>

static MTL::Device *device;
static MTL::CommandQueue *cq;

void initRenderer(MTL::Device *d)
{
  device = d;
  cq = device->newCommandQueue();
}

void render(CA::MetalLayer *layer)
{
  NS::AutoreleasePool *p = NS::AutoreleasePool::alloc()->init();

  MTL::CommandBuffer *cb = cq->commandBuffer();

  MTL::RenderPassDescriptor *rpd = MTL::RenderPassDescriptor::alloc()->init();
  CA::MetalDrawable *d = layer->nextDrawable();
  rpd->colorAttachments()->object(0)->setTexture(d->texture());
  rpd->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
  rpd->colorAttachments()->object(0)->setClearColor(MTL::ClearColor::Make(0.f, 1.f, 0.f, 1.f));

  MTL::RenderCommandEncoder *rce = cb->renderCommandEncoder(rpd);
  rpd->release();
  rce->endEncoding();
  cb->presentDrawable(d);
  cb->commit();

  p->release();
}
