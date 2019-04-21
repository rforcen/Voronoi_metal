//
//  VoronoiDrawer.m
//  Voronoi
//
//  Created by asd on 21/04/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

#import "VoronoiDrawer.h"
#import "ImageBuffer.h"
#import "MetalDevice.h"
#import "voronoi.h"

typedef struct { int x,y; } point;
typedef uint32 color;

@implementation VoronoiDrawer {
    MetalDevice *dev;
    int count;
    point*points;
    color*colors;
}

- (void)awakeFromNib {
    dev = [MetalDevice init];
    count=1500;
    
    points=new point[count];
    colors=new color[count];
}
-(void)createPointsColors:(int)w h:(int)h {
    for (int i=0; i<count; i++) {
        points[i]={(rand() % (w - 10)) + 5, (rand() % (h - 10)) + 5};
        colors[i]=Voronoi::makeColor(rand() % 200 + 50, rand() % 200 + 55, rand() % 200 + 50) ;
    }
}
-(void) setPoints:(color*)pixels w:(int)w {
    for (int i=0; i<count; i++) {
        int x = points[i].x, y = points[i].y;
        for (int i = -1; i <= 1; i++)
            for (int j = -1; j <= 1; j++) pixels[(x + i) + w * (y + j)] = 0xff000000;
    }
}

-(void)generateMetal: (ImageBuffer*)imgBuff size:(int)size width:(int)width height:(int)height count:(int)count {
    [dev compileFunc:@"Voronoi"];
    
    id<MTLBuffer>picBuff=[dev createBuffer:imgBuff.imgBuff length:size],
    pointBuff=[dev createBuffer:points length:count*sizeof(point)],
    colorBuff=[dev createBuffer:colors length:count*sizeof(color)];
    
    [dev setBufferParam: picBuff    index:0]; // shader parameters: picBuff, points, colors, w, h, count
    [dev setBufferParam: pointBuff  index:1];
    [dev setBufferParam: colorBuff  index:2];
    
    [dev setBytesParam:&width        length:sizeof(width)      index:3];
    [dev setBytesParam:&height       length:sizeof(height)     index:4];
    [dev setBytesParam:&count        length:sizeof(count)      index:5];
    
    [dev runThreadsWidth:width height:height];               // setup threads & run in a w x h grid
    [dev copyContentsOn:imgBuff.imgBuff  buffer:picBuff];    // copy result
}

-(void)setPixelsMetal: (ImageBuffer*)imgBuff size:(int)size width:(int)width height:(int)height count:(int)count {
    [dev compileFunc:@"setPointBox"];
    
    id<MTLBuffer>picBuff=[dev createBuffer:imgBuff.imgBuff length:size],
    pointBuff=[dev createBuffer:points length:count*sizeof(point)];
    
    [dev setBufferParam: picBuff    index:0]; // shader parameters: picBuff, points, colors, w, h, count
    [dev setBufferParam: pointBuff  index:1];
    
    [dev setBytesParam:&width        length:sizeof(width)      index:2];
    
    [dev runThreadsWidth:count height:1];               // setup threads 
    [dev copyContentsOn:imgBuff.imgBuff  buffer:picBuff];    // copy result
}


- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    uint w=rect.size.width,
    h=rect.size.height, sizeBytes=w*h*sizeof(uint32);
    
    ImageBuffer*ibuffCPU=[ImageBuffer initWithWidth:w Height:h];
    ImageBuffer*ibuffMetal=[ImageBuffer initWithWidth:w Height:h];
    
    [self createPointsColors:w h:h];
    
    NSTimeInterval tCPU=[MetalDevice timeIt:^{
//        Voronoi voronoi(self->count, w, h, ibuffCPU.imgBuff32);
    }];
    
    NSTimeInterval tGPU=[MetalDevice timeIt:^{
        [self generateMetal:ibuffMetal size:sizeBytes width:w height:h count:self->count];
        [self setPixelsMetal:ibuffMetal size:sizeBytes width:w height:h count:self->count];
        [self setPoints:ibuffMetal.imgBuff32 w:w];
    }];
    
    
//        [[ibuffCPU getimage] drawInRect:rect];
    [[ibuffMetal getimage] drawInRect:rect];
    
    NSLog(@"image size: %dx%d, tiles: %d time CPU: %g, time GPU: %g, ration CPU/GPU: %g",
          w,h, count, tCPU, tGPU, tCPU/tGPU);
}

@end
