// Functions copied from cocos2d-html5
module.exports = (function() {

    var cc = {};

    /**
     * cc.Point is the class for point object, please do not use its constructor to create points, use cc.p() alias function instead.
     * @class cc.Point
     * @param {Number} x
     * @param {Number} y
     * @see cc.p
     */
    cc.Point = function (x, y) {
        this.x = x || 0;
        this.y = y || 0;
    };

    /**
     * Helper function that creates a cc.Point.
     * @function
     * @param {Number|cc.Point} x a Number or a size object
     * @param {Number} y
     * @return {cc.Point}
     * @example
     * var point1 = cc.p();
     * var point2 = cc.p(100, 100);
     * var point3 = cc.p(point2);
     * var point4 = cc.p({x: 100, y: 100});
     */
    cc.p = function (x, y) {
        // This can actually make use of "hidden classes" in JITs and thus decrease
        // memory usage and overall performance drastically
        // return cc.p(x, y);
        // but this one will instead flood the heap with newly allocated hash maps
        // giving little room for optimization by the JIT,
        // note: we have tested this item on Chrome and firefox, it is faster than cc.p(x, y)
        if (x === undefined)
            return {x: 0, y: 0};
        if (y === undefined)
            return {x: x.x, y: x.y};
        return {x: x, y: y};
    };

    /**
     * Check whether a point's value equals to another
     * @function
     * @param {cc.Point} point1
     * @param {cc.Point} point2
     * @return {Boolean}
     */
    cc.pointEqualToPoint = function (point1, point2) {
        return point1 && point2 && (point1.x === point2.x) && (point1.y === point2.y);
    };


    /**
     * cc.Size is the class for size object, please do not use its constructor to create sizes, use cc.size() alias function instead.
     * @class cc.Size
     * @param {Number} width
     * @param {Number} height
     * @see cc.size
     */
    cc.Size = function (width, height) {
        this.width = width || 0;
        this.height = height || 0;
    };

    /**
     * Helper function that creates a cc.Size.
     * @function
     * @param {Number|cc.Size} w width or a size object
     * @param {Number} h height
     * @return {cc.Size}
     * @example
     * var size1 = cc.size();
     * var size2 = cc.size(100,100);
     * var size3 = cc.size(size2);
     * var size4 = cc.size({width: 100, height: 100});
     */
    cc.size = function (w, h) {
        // This can actually make use of "hidden classes" in JITs and thus decrease
        // memory usage and overall performance drastically
        //return cc.size(w, h);
        // but this one will instead flood the heap with newly allocated hash maps
        // giving little room for optimization by the JIT
        // note: we have tested this item on Chrome and firefox, it is faster than cc.size(w, h)
        if (w === undefined)
            return {width: 0, height: 0};
        if (h === undefined)
            return {width: w.width, height: w.height};
        return {width: w, height: h};
    };

    /**
     * Check whether a point's value equals to another
     * @function
     * @param {cc.Size} size1
     * @param {cc.Size} size2
     * @return {Boolean}
     */
    cc.sizeEqualToSize = function (size1, size2) {
        return (size1 && size2 && (size1.width === size2.width) && (size1.height === size2.height));
    };


    /**
     * cc.Rect is the class for rect object, please do not use its constructor to create rects, use cc.rect() alias function instead.
     * @class cc.Rect
     * @param {Number} width
     * @param {Number} height
     * @see cc.rect
     */
    cc.Rect = function (x, y, width, height) {
        this.x = x||0;
        this.y = y||0;
        this.width = width||0;
        this.height = height||0;
    };

    /**
     * Helper function that creates a cc.Rect.
     * @function
     * @param {Number|cc.Rect} x a number or a rect object
     * @param {Number} y
     * @param {Number} w
     * @param {Number} h
     * @returns {cc.Rect}
     * @example
     * var rect1 = cc.rect();
     * var rect2 = cc.rect(100,100,100,100);
     * var rect3 = cc.rect(rect2);
     * var rect4 = cc.rect({x: 100, y: 100, width: 100, height: 100});
     */
    cc.rect = function (x, y, w, h) {
        if (x === undefined)
            return {x: 0, y: 0, width: 0, height: 0};
        if (y === undefined)
            return {x: x.x, y: x.y, width: x.width, height: x.height};
        return {x: x, y: y, width: w, height: h };
    };

    /**
     * Check whether a rect's value equals to another
     * @function
     * @param {cc.Rect} rect1
     * @param {cc.Rect} rect2
     * @return {Boolean}
     */
    cc.rectEqualToRect = function (rect1, rect2) {
        return rect1 && rect2 && (rect1.x === rect2.x) && (rect1.y === rect2.y) && (rect1.width === rect2.width) && (rect1.height === rect2.height);
    };

    cc._rectEqualToZero = function(rect){
        return rect && (rect.x === 0) && (rect.y === 0) && (rect.width === 0) && (rect.height === 0);
    };

    /**
     * Check whether the rect1 contains rect2
     * @function
     * @param {cc.Rect} rect1
     * @param {cc.Rect} rect2
     * @return {Boolean}
     */
    cc.rectContainsRect = function (rect1, rect2) {
        if (!rect1 || !rect2)
            return false;
        return !((rect1.x >= rect2.x) || (rect1.y >= rect2.y) ||
        ( rect1.x + rect1.width <= rect2.x + rect2.width) ||
        ( rect1.y + rect1.height <= rect2.y + rect2.height));
    };

    /**
     * Returns the rightmost x-value of a rect
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The rightmost x value
     */
    cc.rectGetMaxX = function (rect) {
        return (rect.x + rect.width);
    };

    /**
     * Return the midpoint x-value of a rect
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The midpoint x value
     */
    cc.rectGetMidX = function (rect) {
        return (rect.x + rect.width / 2.0);
    };
    /**
     * Returns the leftmost x-value of a rect
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The leftmost x value
     */
    cc.rectGetMinX = function (rect) {
        return rect.x;
    };

    /**
     * Return the topmost y-value of a rect
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The topmost y value
     */
    cc.rectGetMaxY = function (rect) {
        return(rect.y + rect.height);
    };

    /**
     * Return the midpoint y-value of `rect'
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The midpoint y value
     */
    cc.rectGetMidY = function (rect) {
        return rect.y + rect.height / 2.0;
    };

    /**
     * Return the bottommost y-value of a rect
     * @function
     * @param {cc.Rect} rect
     * @return {Number} The bottommost y value
     */
    cc.rectGetMinY = function (rect) {
        return rect.y;
    };

    /**
     * Check whether a rect contains a point
     * @function
     * @param {cc.Rect} rect
     * @param {cc.Point} point
     * @return {Boolean}
     */
    cc.rectContainsPoint = function (rect, point) {
        return (point.x >= cc.rectGetMinX(rect) && point.x <= cc.rectGetMaxX(rect) &&
        point.y >= cc.rectGetMinY(rect) && point.y <= cc.rectGetMaxY(rect)) ;
    };

    /**
     * Check whether a rect intersect with another
     * @function
     * @param {cc.Rect} rectA
     * @param {cc.Rect} rectB
     * @return {Boolean}
     */
    cc.rectIntersectsRect = function (ra, rb) {
        var maxax = ra.x + ra.width,
            maxay = ra.y + ra.height,
            maxbx = rb.x + rb.width,
            maxby = rb.y + rb.height;
        return !(maxax < rb.x || maxbx < ra.x || maxay < rb.y || maxby < ra.y);
    };

    /**
     * Check whether a rect overlaps another
     * @function
     * @param {cc.Rect} rectA
     * @param {cc.Rect} rectB
     * @return {Boolean}
     */
    cc.rectOverlapsRect = function (rectA, rectB) {
        return !((rectA.x + rectA.width < rectB.x) ||
        (rectB.x + rectB.width < rectA.x) ||
        (rectA.y + rectA.height < rectB.y) ||
        (rectB.y + rectB.height < rectA.y));
    };

    /**
     * Returns the smallest rectangle that contains the two source rectangles.
     * @function
     * @param {cc.Rect} rectA
     * @param {cc.Rect} rectB
     * @return {cc.Rect}
     */
    cc.rectUnion = function (rectA, rectB) {
        var rect = cc.rect(0, 0, 0, 0);
        rect.x = Math.min(rectA.x, rectB.x);
        rect.y = Math.min(rectA.y, rectB.y);
        rect.width = Math.max(rectA.x + rectA.width, rectB.x + rectB.width) - rect.x;
        rect.height = Math.max(rectA.y + rectA.height, rectB.y + rectB.height) - rect.y;
        return rect;
    };

    /**
     * Returns the overlapping portion of 2 rectangles
     * @function
     * @param {cc.Rect} rectA
     * @param {cc.Rect} rectB
     * @return {cc.Rect}
     */
    cc.rectIntersection = function (rectA, rectB) {
        var intersection = cc.rect(
            Math.max(cc.rectGetMinX(rectA), cc.rectGetMinX(rectB)),
            Math.max(cc.rectGetMinY(rectA), cc.rectGetMinY(rectB)),
            0, 0);

        intersection.width = Math.min(cc.rectGetMaxX(rectA), cc.rectGetMaxX(rectB)) - cc.rectGetMinX(intersection);
        intersection.height = Math.min(cc.rectGetMaxY(rectA), cc.rectGetMaxY(rectB)) - cc.rectGetMinY(intersection);
        return intersection;
    };



    /**
     * smallest such that 1.0+FLT_EPSILON != 1.0
     * @constant
     * @type Number
     */
    cc.POINT_EPSILON = parseFloat('1.192092896e-07F');

    /**
     * Returns opposite of point.
     * @param {cc.Point} point
     * @return {cc.Point}
     */
    cc.pNeg = function (point) {
        return cc.p(-point.x, -point.y);
    };

    /**
     * Calculates sum of two points.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {cc.Point}
     */
    cc.pAdd = function (v1, v2) {
        return cc.p(v1.x + v2.x, v1.y + v2.y);
    };

    /**
     * Calculates difference of two points.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {cc.Point}
     */
    cc.pSub = function (v1, v2) {
        return cc.p(v1.x - v2.x, v1.y - v2.y);
    };

    /**
     * Returns point multiplied by given factor.
     * @param {cc.Point} point
     * @param {Number} floatVar
     * @return {cc.Point}
     */
    cc.pMult = function (point, floatVar) {
        return cc.p(point.x * floatVar, point.y * floatVar);
    };

    /**
     * Calculates midpoint between two points.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {cc.pMult}
     */
    cc.pMidpoint = function (v1, v2) {
        return cc.pMult(cc.pAdd(v1, v2), 0.5);
    };

    /**
     * Calculates dot product of two points.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {Number}
     */
    cc.pDot = function (v1, v2) {
        return v1.x * v2.x + v1.y * v2.y;
    };

    /**
     * Calculates cross product of two points.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {Number}
     */
    cc.pCross = function (v1, v2) {
        return v1.x * v2.y - v1.y * v2.x;
    };

    /**
     * Calculates perpendicular of v, rotated 90 degrees counter-clockwise -- cross(v, perp(v)) >= 0
     * @param {cc.Point} point
     * @return {cc.Point}
     */
    cc.pPerp = function (point) {
        return cc.p(-point.y, point.x);
    };

    /**
     * Calculates perpendicular of v, rotated 90 degrees clockwise -- cross(v, rperp(v)) <= 0
     * @param {cc.Point} point
     * @return {cc.Point}
     */
    cc.pRPerp = function (point) {
        return cc.p(point.y, -point.x);
    };

    /**
     * Calculates the projection of v1 over v2.
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {cc.pMult}
     */
    cc.pProject = function (v1, v2) {
        return cc.pMult(v2, cc.pDot(v1, v2) / cc.pDot(v2, v2));
    };

    /**
     * Rotates two points.
     * @param  {cc.Point} v1
     * @param  {cc.Point} v2
     * @return {cc.Point}
     */
    cc.pRotate = function (v1, v2) {
        return cc.p(v1.x * v2.x - v1.y * v2.y, v1.x * v2.y + v1.y * v2.x);
    };

    /**
     * Unrotates two points.
     * @param  {cc.Point} v1
     * @param  {cc.Point} v2
     * @return {cc.Point}
     */
    cc.pUnrotate = function (v1, v2) {
        return cc.p(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y);
    };

    /**
     * Calculates the square length of a cc.Point (not calling sqrt() )
     * @param  {cc.Point} v
     *@return {Number}
     */
    cc.pLengthSQ = function (v) {
        return cc.pDot(v, v);
    };

    /**
     * Calculates the square distance between two points (not calling sqrt() )
     * @param {cc.Point} point1
     * @param {cc.Point} point2
     * @return {Number}
     */
    cc.pDistanceSQ = function (point1, point2) {
        return cc.pLengthSQ(cc.pSub(point1, point2));
    };

    /**
     * Calculates distance between point an origin
     * @param  {cc.Point} v
     * @return {Number}
     */
    cc.pLength = function (v) {
        return Math.sqrt(cc.pLengthSQ(v));
    };

    /**
     * Calculates the distance between two points
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     * @return {Number}
     */
    cc.pDistance = function (v1, v2) {
        return cc.pLength(cc.pSub(v1, v2));
    };

    /**
     * Returns point multiplied to a length of 1.
     * @param {cc.Point} v
     * @return {cc.Point}
     */
    cc.pNormalize = function (v) {
        return cc.pMult(v, 1.0 / cc.pLength(v));
    };

    /**
     * Converts radians to a normalized vector.
     * @param {Number} a
     * @return {cc.Point}
     */
    cc.pForAngle = function (a) {
        return cc.p(Math.cos(a), Math.sin(a));
    };

    /**
     * Converts a vector to radians.
     * @param {cc.Point} v
     * @return {Number}
     */
    cc.pToAngle = function (v) {
        return Math.atan2(v.y, v.x);
    };

    /**
     * Clamp a value between from and to.
     * @param {Number} value
     * @param {Number} min_inclusive
     * @param {Number} max_inclusive
     * @return {Number}
     */
    cc.clampf = function (value, min_inclusive, max_inclusive) {
        if (min_inclusive > max_inclusive) {
            var temp = min_inclusive;
            min_inclusive = max_inclusive;
            max_inclusive = temp;
        }
        return value < min_inclusive ? min_inclusive : value < max_inclusive ? value : max_inclusive;
    };

    /**
     * Clamp a point between from and to.
     * @param {Point} p
     * @param {Number} min_inclusive
     * @param {Number} max_inclusive
     * @return {cc.Point}
     */
    cc.pClamp = function (p, min_inclusive, max_inclusive) {
        return cc.p(cc.clampf(p.x, min_inclusive.x, max_inclusive.x), cc.clampf(p.y, min_inclusive.y, max_inclusive.y));
    };

    /**
     * Quickly convert cc.Size to a cc.Point
     * @param {cc.Size} s
     * @return {cc.Point}
     */
    cc.pFromSize = function (s) {
        return cc.p(s.width, s.height);
    };

    /**
     * Run a math operation function on each point component <br />
     * Math.abs, Math.fllor, Math.ceil, Math.round.
     * @param {cc.Point} p
     * @param {Function} opFunc
     * @return {cc.Point}
     * @example
     * //For example: let's try to take the floor of x,y
     * var p = cc.pCompOp(cc.p(10,10),Math.abs);
     */
    cc.pCompOp = function (p, opFunc) {
        return cc.p(opFunc(p.x), opFunc(p.y));
    };

    /**
     * Linear Interpolation between two points a and b
     * alpha == 0 ? a
     * alpha == 1 ? b
     * otherwise a value between a..b
     * @param {cc.Point} a
     * @param {cc.Point} b
     * @param {Number} alpha
     * @return {cc.pAdd}
     */
    cc.pLerp = function (a, b, alpha) {
        return cc.pAdd(cc.pMult(a, 1 - alpha), cc.pMult(b, alpha));
    };

    /**
     * @param {cc.Point} a
     * @param {cc.Point} b
     * @param {Number} variance
     * @return {Boolean} if points have fuzzy equality which means equal with some degree of variance.
     */
    cc.pFuzzyEqual = function (a, b, variance) {
        if (a.x - variance <= b.x && b.x <= a.x + variance) {
            if (a.y - variance <= b.y && b.y <= a.y + variance) {
                return true;
            }
        }
        return false;
    };

    /**
     * Multiplies a nd b components, a.x*b.x, a.y*b.y
     * @param {cc.Point} a
     * @param {cc.Point} b
     * @return {cc.Point}
     */
    cc.pCompMult = function (a, b) {
        return cc.p(a.x * b.x, a.y * b.y);
    };

    /**
     * @param {cc.Point} a
     * @param {cc.Point} b
     * @return {Number} the signed angle in radians between two vector directions
     */
    cc.pAngleSigned = function (a, b) {
        var a2 = cc.pNormalize(a);
        var b2 = cc.pNormalize(b);
        var angle = Math.atan2(a2.x * b2.y - a2.y * b2.x, cc.pDot(a2, b2));
        if (Math.abs(angle) < cc.POINT_EPSILON)
            return 0.0;
        return angle;
    };

    /**
     * @param {cc.Point} a
     * @param {cc.Point} b
     * @return {Number} the angle in radians between two vector directions
     */
    cc.pAngle = function (a, b) {
        var angle = Math.acos(cc.pDot(cc.pNormalize(a), cc.pNormalize(b)));
        if (Math.abs(angle) < cc.POINT_EPSILON) return 0.0;
        return angle;
    };

    /**
     * Rotates a point counter clockwise by the angle around a pivot
     * @param {cc.Point} v v is the point to rotate
     * @param {cc.Point} pivot pivot is the pivot, naturally
     * @param {Number} angle angle is the angle of rotation cw in radians
     * @return {cc.Point} the rotated point
     */
    cc.pRotateByAngle = function (v, pivot, angle) {
        var r = cc.pSub(v, pivot);
        var cosa = Math.cos(angle), sina = Math.sin(angle);
        var t = r.x;
        r.x = t * cosa - r.y * sina + pivot.x;
        r.y = t * sina + r.y * cosa + pivot.y;
        return r;
    };

    /**
     * A general line-line intersection test
     * indicating successful intersection of a line<br />
     * note that to truly test intersection for segments we have to make<br />
     * sure that s & t lie within [0..1] and for rays, make sure s & t > 0<br />
     * the hit point is        p3 + t * (p4 - p3);<br />
     * the hit point also is    p1 + s * (p2 - p1);
     * @param {cc.Point} A A is the startpoint for the first line P1 = (p1 - p2).
     * @param {cc.Point} B B is the endpoint for the first line P1 = (p1 - p2).
     * @param {cc.Point} C C is the startpoint for the second line P2 = (p3 - p4).
     * @param {cc.Point} D D is the endpoint for the second line P2 = (p3 - p4).
     * @param {cc.Point} retP retP.x is the range for a hitpoint in P1 (pa = p1 + s*(p2 - p1)), <br />
     * retP.y is the range for a hitpoint in P3 (pa = p2 + t*(p4 - p3)).
     * @return {Boolean}
     */
    cc.pLineIntersect = function (A, B, C, D, retP) {
        if ((A.x === B.x && A.y === B.y) || (C.x === D.x && C.y === D.y)) {
            return false;
        }
        var BAx = B.x - A.x;
        var BAy = B.y - A.y;
        var DCx = D.x - C.x;
        var DCy = D.y - C.y;
        var ACx = A.x - C.x;
        var ACy = A.y - C.y;

        var denom = DCy * BAx - DCx * BAy;

        retP.x = DCx * ACy - DCy * ACx;
        retP.y = BAx * ACy - BAy * ACx;

        if (denom === 0) {
            if (retP.x === 0 || retP.y === 0) {
                // Lines incident
                return true;
            }
            // Lines parallel and not incident
            return false;
        }

        retP.x = retP.x / denom;
        retP.y = retP.y / denom;

        return true;
    };

    /**
     * ccpSegmentIntersect return YES if Segment A-B intersects with segment C-D.
     * @param {cc.Point} A
     * @param {cc.Point} B
     * @param {cc.Point} C
     * @param {cc.Point} D
     * @return {Boolean}
     */
    cc.pSegmentIntersect = function (A, B, C, D) {
        var retP = cc.p(0, 0);
        if (cc.pLineIntersect(A, B, C, D, retP))
            if (retP.x >= 0.0 && retP.x <= 1.0 && retP.y >= 0.0 && retP.y <= 1.0)
                return true;
        return false;
    };

    /**
     * ccpIntersectPoint return the intersection point of line A-B, C-D
     * @param {cc.Point} A
     * @param {cc.Point} B
     * @param {cc.Point} C
     * @param {cc.Point} D
     * @return {cc.Point}
     */
    cc.pIntersectPoint = function (A, B, C, D) {
        var retP = cc.p(0, 0);

        if (cc.pLineIntersect(A, B, C, D, retP)) {
            // Point of intersection
            var P = cc.p(0, 0);
            P.x = A.x + retP.x * (B.x - A.x);
            P.y = A.y + retP.x * (B.y - A.y);
            return P;
        }

        return cc.p(0, 0);
    };

    /**
     * check to see if both points are equal
     * @param {cc.Point} A A ccp a
     * @param {cc.Point} B B ccp b to be compared
     * @return {Boolean} the true if both ccp are same
     */
    cc.pSameAs = function (A, B) {
        if ((A != null) && (B != null)) {
            return (A.x === B.x && A.y === B.y);
        }
        return false;
    };


// High Perfomance In Place Operationrs ---------------------------------------

    /**
     * sets the position of the point to 0
     * @param {cc.Point} v
     */
    cc.pZeroIn = function (v) {
        v.x = 0;
        v.y = 0;
    };

    /**
     * copies the position of one point to another
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     */
    cc.pIn = function (v1, v2) {
        v1.x = v2.x;
        v1.y = v2.y;
    };

    /**
     * multiplies the point with the given factor (inplace)
     * @param {cc.Point} point
     * @param {Number} floatVar
     */
    cc.pMultIn = function (point, floatVar) {
        point.x *= floatVar;
        point.y *= floatVar;
    };

    /**
     * subtracts one point from another (inplace)
     * @param {cc.Point} v1
     * @param {cc.Point} v2
     */
    cc.pSubIn = function (v1, v2) {
        v1.x -= v2.x;
        v1.y -= v2.y;
    };

    /**
     * adds one point to another (inplace)
     * @param {cc.Point} v1
     * @param {cc.point} v2
     */
    cc.pAddIn = function (v1, v2) {
        v1.x += v2.x;
        v1.y += v2.y;
    };

    /**
     * normalizes the point (inplace)
     */
    cc.pNormalizeIn = function (v) {
        cc.pMultIn(v, 1.0 / Math.sqrt(v.x * v.x + v.y * v.y));
    };

    cc.each = function (obj, iterator, context) {
        if (!obj)
            return;
        if (obj instanceof Array) {
            for (var i = 0, li = obj.length; i < li; i++) {
                if (iterator.call(context, obj[i], i) === false)
                    return;
            }
        } else {
            for (var key in obj) {
                if (iterator.call(context, obj[key], key) === false)
                    return;
            }
        }
    };

    /**
     * Copy all of the properties in source objects to target object and return the target object.
     * @param {object} target
     * @param {object} *sources
     * @returns {object}
     */
    cc.extend = function(target) {
        var sources = arguments.length >= 2 ? Array.prototype.slice.call(arguments, 1) : [];

        cc.each(sources, function(src) {
            for(var key in src) {
                if (src.hasOwnProperty(key)) {
                    target[key] = src[key];
                }
            }
        });
        return target;
    };

    /**
     * Check the obj whether is function or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isFunction = function(obj) {
        return typeof obj === 'function';
    };

    /**
     * Check the obj whether is number or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isNumber = function(obj) {
        return typeof obj === 'number' || Object.prototype.toString.call(obj) === '[object Number]';
    };

    /**
     * Check the obj whether is string or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isString = function(obj) {
        return typeof obj === 'string' || Object.prototype.toString.call(obj) === '[object String]';
    };

    /**
     * Check the obj whether is array or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isArray = function(obj) {
        return Object.prototype.toString.call(obj) === '[object Array]';
    };

    /**
     * Check the obj whether is undefined or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isUndefined = function(obj) {
        return typeof obj === 'undefined';
    };

    /**
     * Check the obj whether is object or not
     * @param {*} obj
     * @returns {boolean}
     */
    cc.isObject = function(obj) {
        var type = typeof obj;

        return type === 'function' || (obj && type === 'object');
    };

    //+++++++++++++++++++++++++something about path begin++++++++++++++++++++++++++++++++
    /**
     * @class
     */
    cc.path = /** @lends cc.path# */{
        /**
         * Join strings to be a path.
         * @example
         cc.path.join("a", "b.png");//-->"a/b.png"
         cc.path.join("a", "b", "c.png");//-->"a/b/c.png"
         cc.path.join("a", "b");//-->"a/b"
         cc.path.join("a", "b", "/");//-->"a/b/"
         cc.path.join("a", "b/", "/");//-->"a/b/"
         * @returns {string}
         */
        join: function () {
            var l = arguments.length;
            var result = "";
            for (var i = 0; i < l; i++) {
                result = (result + (result === "" ? "" : "/") + arguments[i]).replace(/(\/|\\\\)$/, "");
            }
            return result;
        },

        /**
         * Get the ext name of a path.
         * @example
         cc.path.extname("a/b.png");//-->".png"
         cc.path.extname("a/b.png?a=1&b=2");//-->".png"
         cc.path.extname("a/b");//-->null
         cc.path.extname("a/b?a=1&b=2");//-->null
         * @param {string} pathStr
         * @returns {*}
         */
        extname: function (pathStr) {
            var temp = /(\.[^\.\/\?\\]*)(\?.*)?$/.exec(pathStr);
            return temp ? temp[1] : null;
        },

        /**
         * Get the main name of a file name
         * @param {string} fileName
         * @returns {string}
         */
        mainFileName: function(fileName){
            if(fileName){
                var idx = fileName.lastIndexOf(".");
                if(idx !== -1)
                    return fileName.substring(0,idx);
            }
            return fileName;
        },

        /**
         * Get the file name of a file path.
         * @example
         cc.path.basename("a/b.png");//-->"b.png"
         cc.path.basename("a/b.png?a=1&b=2");//-->"b.png"
         cc.path.basename("a/b.png", ".png");//-->"b"
         cc.path.basename("a/b.png?a=1&b=2", ".png");//-->"b"
         cc.path.basename("a/b.png", ".txt");//-->"b.png"
         * @param {string} pathStr
         * @param {string} [extname]
         * @returns {*}
         */
        basename: function (pathStr, extname) {
            var index = pathStr.indexOf("?");
            if (index > 0) pathStr = pathStr.substring(0, index);
            var reg = /(\/|\\\\)([^(\/|\\\\)]+)$/g;
            var result = reg.exec(pathStr.replace(/(\/|\\\\)$/, ""));
            if (!result) return null;
            var baseName = result[2];
            if (extname && pathStr.substring(pathStr.length - extname.length).toLowerCase() === extname.toLowerCase())
                return baseName.substring(0, baseName.length - extname.length);
            return baseName;
        },

        /**
         * Get dirname of a file path.
         * @example
         * unix
         cc.path.driname("a/b/c.png");//-->"a/b"
         cc.path.driname("a/b/c.png?a=1&b=2");//-->"a/b"
         cc.path.dirname("a/b/");//-->"a/b"
         cc.path.dirname("c.png");//-->""
         * windows
         cc.path.driname("a\\b\\c.png");//-->"a\b"
         cc.path.driname("a\\b\\c.png?a=1&b=2");//-->"a\b"
         * @param {string} pathStr
         * @returns {*}
         */
        dirname: function (pathStr) {
            return pathStr.replace(/((.*)(\/|\\|\\\\))?(.*?\..*$)?/, '$2');
        },

        /**
         * Change extname of a file path.
         * @example
         cc.path.changeExtname("a/b.png", ".plist");//-->"a/b.plist"
         cc.path.changeExtname("a/b.png?a=1&b=2", ".plist");//-->"a/b.plist?a=1&b=2"
         * @param {string} pathStr
         * @param {string} [extname]
         * @returns {string}
         */
        changeExtname: function (pathStr, extname) {
            extname = extname || "";
            var index = pathStr.indexOf("?");
            var tempStr = "";
            if (index > 0) {
                tempStr = pathStr.substring(index);
                pathStr = pathStr.substring(0, index);
            }
            index = pathStr.lastIndexOf(".");
            if (index < 0) return pathStr + extname + tempStr;
            return pathStr.substring(0, index) + extname + tempStr;
        },
        /**
         * Change file name of a file path.
         * @example
         cc.path.changeBasename("a/b/c.plist", "b.plist");//-->"a/b/b.plist"
         cc.path.changeBasename("a/b/c.plist?a=1&b=2", "b.plist");//-->"a/b/b.plist?a=1&b=2"
         cc.path.changeBasename("a/b/c.plist", ".png");//-->"a/b/c.png"
         cc.path.changeBasename("a/b/c.plist", "b");//-->"a/b/b"
         cc.path.changeBasename("a/b/c.plist", "b", true);//-->"a/b/b.plist"
         * @param {String} pathStr
         * @param {String} basename
         * @param {Boolean} [isSameExt]
         * @returns {string}
         */
        changeBasename: function (pathStr, basename, isSameExt) {
            if (basename.indexOf(".") === 0) return this.changeExtname(pathStr, basename);
            var index = pathStr.indexOf("?");
            var tempStr = "";
            var ext = isSameExt ? this.extname(pathStr) : "";
            if (index > 0) {
                tempStr = pathStr.substring(index);
                pathStr = pathStr.substring(0, index);
            }
            index = pathStr.lastIndexOf("/");
            index = index <= 0 ? 0 : index + 1;
            return pathStr.substring(0, index) + basename + ext + tempStr;
        }
    };

//+++++++++++++++++++++++++something about path end++++++++++++++++++++++++++++++++
    /**
     * A string tool to construct a string with format string.
     * for example:
     *      cc.formatStr("a: %d, b: %b", a, b);
     *      cc.formatStr(a, b, c);
     * @returns {String}
     */
    cc.formatStr = function(){
        var args = arguments;
        var l = args.length;
        if(l < 1)
            return "";

        var str = args[0];
        var needToFormat = true;
        if(typeof str === "object"){
            needToFormat = false;
        }
        for(var i = 1; i < l; ++i){
            var arg = args[i];
            if(needToFormat){
                while(true){
                    var result = null;
                    if(typeof arg === "number"){
                        result = str.match(/(%d)|(%s)/);
                        if(result){
                            str = str.replace(/(%d)|(%s)/, arg);
                            break;
                        }
                    }
                    result = str.match(/%s/);
                    if(result)
                        str = str.replace(/%s/, arg);
                    else
                        str += "    " + arg;
                    break;
                }
            }else
                str += "    " + arg;
        }
        return str;
    };

    /**
     * @constant
     * @type Number
     */
    cc.INVALID_INDEX = -1;

    /**
     * PI is the ratio of a circle's circumference to its diameter.
     * @constant
     * @type Number
     */
    cc.PI = Math.PI;

    /**
     * @constant
     * @type Number
     */
    cc.FLT_MAX = parseFloat('3.402823466e+38F');

    /**
     * @constant
     * @type Number
     */
    cc.FLT_MIN = parseFloat("1.175494351e-38F");

    /**
     * @constant
     * @type Number
     */
    cc.RAD = cc.PI / 180;

    /**
     * @constant
     * @type Number
     */
    cc.DEG = 180 / cc.PI;

    /**
     * maximum unsigned int value
     * @constant
     * @type Number
     */
    cc.UINT_MAX = 0xffffffff;

    /**
     * <p>
     * simple macro that swaps 2 variables<br/>
     *  modified from c++ macro, you need to pass in the x and y variables names in string, <br/>
     *  and then a reference to the whole object as third variable
     * </p>
     * @param {String} x
     * @param {String} y
     * @param {Object} ref
     * @function
     * @deprecated since v3.0
     */
    cc.swap = function (x, y, ref) {
        if (cc.isObject(ref) && !cc.isUndefined(ref.x) && !cc.isUndefined(ref.y)) {
            var tmp = ref[x];
            ref[x] = ref[y];
            ref[y] = tmp;
        } else
            cc.log(cc._LogInfos.swap);
    };

    /**
     * <p>
     *     Linear interpolation between 2 numbers, the ratio sets how much it is biased to each end
     * </p>
     * @param {Number} a number A
     * @param {Number} b number B
     * @param {Number} r ratio between 0 and 1
     * @function
     * @example
     * cc.lerp(2,10,0.5)//returns 6<br/>
     * cc.lerp(2,10,0.2)//returns 3.6
     */
    cc.lerp = function (a, b, r) {
        return a + (b - a) * r;
    };

    /**
     * get a random number from 0 to 0xffffff
     * @function
     * @returns {number}
     */
    cc.rand = function () {
        return Math.random() * 0xffffff;
    };

    /**
     * returns a random float between -1 and 1
     * @return {Number}
     * @function
     */
    cc.randomMinus1To1 = function () {
        return (Math.random() - 0.5) * 2;
    };

    /**
     * returns a random float between 0 and 1
     * @return {Number}
     * @function
     */
    cc.random0To1 = Math.random;

    /**
     * converts degrees to radians
     * @param {Number} angle
     * @return {Number}
     * @function
     */
    cc.degreesToRadians = function (angle) {
        return angle * cc.RAD;
    };

    /**
     * converts radians to degrees
     * @param {Number} angle
     * @return {Number}
     * @function
     */
    cc.radiansToDegrees = function (angle) {
        return angle * cc.DEG;
    };
    /**
     * converts radians to degrees
     * @param {Number} angle
     * @return {Number}
     * @function
     */
    cc.radiansToDegress = function (angle) {
        cc.log(cc._LogInfos.radiansToDegress);
        return angle * cc.DEG;
    };

    return cc;
})();
