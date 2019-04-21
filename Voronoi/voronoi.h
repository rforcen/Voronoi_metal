#ifndef VORONOI_H
#define VORONOI_H
// Voronoi graphs

#include <vector>

using namespace std;

class Voronoi {
    typedef uint32 color;
    typedef struct { int x, y; } point;
    
public:
    Voronoi(int count, int w, int h, color*bmp) : w(w), h(h), wh(w*h), bmp(bmp) {
        createRandomPoints(count);
        
        genPixels();
        setPoints();
    }
    ~Voronoi() {}
    
    color*getPixels() { return bmp; }
    static inline color makeColor(int r, int g, int b) { return 0xff000000 | (r|(g<<8)|(b<<16));}
    
private:
    color* bmp = nullptr;
    int w, h, wh;
    vector<point> points;
    vector<color> colors;
    
    
    inline void setPixel(int x, int y, color c) {
        int ix = x + y * w;
        bmp[ix] = c;
    }
    
    inline int sqMag(point& pnt, int x, int y) {
        int xd = x - pnt.x;
        int yd = y - pnt.y;
        return (xd * xd) + (yd * yd);
    }
    
    color* genPixels() {
        
        int d;
        for (int hh = 0; hh < h; hh++) {
            for (int ww = 0; ww < w; ww++) {
                int ind = -1, dist = INT_MAX;
                
                for (size_t it = 0; it < points.size(); it++) {
                    d = sqMag(points[it], ww, hh);
                    if (d < dist) {
                        dist = d;
                        ind = (int)it;
                    }
                }
                
                if (ind > -1) setPixel(ww, hh, colors[ind]);
            }
        }
        return bmp;
    }
    
    void setPoints() {
        for (auto pnt : points) {
            int x = pnt.x, y = pnt.y;
            for (int i = -1; i <= 1; i++)
                for (int j = -1; j <= 1; j++) setPixel(x + i, y + j, 0);
        }
    }
    
    void createRandomPoints(int count) {
        points.clear();
        colors.clear();
        for (int i = 0; i < count; i++) {
            points.push_back({(rand() % (w - 10)) + 5, (rand() % (h - 10)) + 5});
            colors.push_back(makeColor(rand() % 200 + 50, rand() % 200 + 55, rand() % 200 + 50) );
        }
    }
    
};

#endif  // VORONOI_H
