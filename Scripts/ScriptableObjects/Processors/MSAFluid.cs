
/***********************************************************************
 
 Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 * ***********************************************************************/



using UnityEngine;
/**
* this is a class for solving real-time fluid dynamics simulations based on Navier-Stokes equations 
* and code from Jos Stam's paper "Real-Time Fluid Dynamics for Games" http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
* Other useful resources and implementations I looked at while building this lib: 
* Mike Ash (C) - http://mikeash.com/?page=pyblog/fluid-simulation-for-dummies.html
* Alexander McKenzie (Java) - http://www.multires.caltech.edu/teaching/demos/java/stablefluids.htm
* Pierluigi Pesenti (AS3 port of Alexander's) - http://blog.oaxoa.com/2008/01/21/actionscript-3-fluids-simulation/
* Gustav Taxen (C) - http://www.nada.kth.se/~gustavt/fluids/
* Dave Wallin (C++) - http://nuigroup.com/touchlib/ (uses portions from Gustav's)
* 
* 
* @example MSAFluid 
* @author Memo Akten
* 
*/
public class MSAFluidSolver2D
{
    public float[] r;
    public float[] g;
    public float[] b;

    public float[] u;
    public float[] v;

    public float[] rOld;
    public float[] gOld;
    public float[] bOld;

    public float[] uOld;
    public float[] vOld;

    public static float FLUID_DEFAULT_DT = 1.0f; // timestep
    public static float FLUID_DEFAULT_VISC = 0.0001f; // viscosity
    public static float FLUID_DEFAULT_FADESPEED = 0; // how fast the fluid dye dissipates and fades out
    public static int FLUID_DEFAULT_SOLVER_ITERATIONS = 10; // how many iterations solver should run per update


    /**
	 * Constructor to initialize solver and setup number of cells
	 * @param NX number of cells in X direction
	 * @param NY number of cells in Y direction
	 */
    public MSAFluidSolver2D(int NX, int NY)
    {
        r = null;
        rOld = null;

        g = null;
        gOld = null;

        b = null;
        bOld = null;

        u = null;
        uOld = null;
        v = null;
        vOld = null;

        _isInited = false;
        setup(NX, NY);
    }


    /**
	 * (OPTIONAL SETUP) re-initialize solver and setup number of cells
	 * @param NX number of cells in X direction
	 * @param NY number of cells in X direction
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D setup(int NX, int NY)
    {

        setDeltaT(FLUID_DEFAULT_DT);
        setFadeSpeed(FLUID_DEFAULT_FADESPEED);
        setSolverIterations(FLUID_DEFAULT_SOLVER_ITERATIONS);

        _NX = NX;
        _NY = NY;
        _numCells = (_NX + 2) * (_NY + 2);
        _invNumCells = 1.0f / _numCells;
        //    reset();

        _invNX = 1.0f / _NX;
        _invNY = 1.0f / _NY;

        width = getWidth();
        height = getHeight();
        invWidth = 1.0f / width;
        invHeight = 1.0f / height;

        reset();
        enableRGB(false);
        return this;
    }


    /**
	 * (OPTIONAL SETUP) set timestep
	 * @param dt timestep
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D setDeltaT(float dt)
    {
        _dt = dt;
        return this;
    }


    /**
	 * (OPTIONAL SETUP) set how quickly the fluid dye dissipates and fades out 
	 * @param fadeSpeed (0...1)
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D setFadeSpeed(float fadeSpeed)
    {
        _fadeSpeed = fadeSpeed;
        return this;
    }


    /**
	 * (OPTIONAL SETUP) set number of iterations for solver (higher is slower but more accurate) 
	 * @param solverIterations
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D setSolverIterations(int solverIterations)
    {
        _solverIterations = solverIterations;
        return this;
    }

    /**
	 * (OPTIONAL SETUP) set whether solver should work with monochrome dye (default) or RGB
	 * @param isRGB true or false
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D enableRGB(bool isRGB)
    {
        _isRGB = isRGB;
        return this;
    }

    /**
	 * (OPTIONAL SETUP) set viscosity
	 * @param newVisc
	 * @return instance of MSAFluidSolver2D for further configuration
	 */
    public MSAFluidSolver2D setVisc(float newVisc)
    {
        visc = newVisc;
        return this;
    }


    /**
	 * (OPTIONAL SETUP) randomize dye (useful for debugging)
	 */
    public void randomizeColor()
    {
        for (int i = 0; i < getWidth(); i++)
        {
            for (int j = 0; j < getHeight(); j++)
            {
                int index = FLUID_IX(i, j);
                r[index] = rOld[index] = (float)Random.value;
                if (_isRGB)
                {
                    g[index] = gOld[index] = (float)Random.value;
                    b[index] = bOld[index] = (float)Random.value;
                }
            }
        }
    }

    /**
	 * destroy solver and release all memory
	 */
    public void destroy()
    {
        _isInited = false;

        r = null;
        rOld = null;

        g = null;
        gOld = null;

        b = null;
        bOld = null;

        u = null;
        uOld = null;
        v = null;
        vOld = null;
    }


    /**
	 * initialize solver (remove all velocities and dye)
	*/
    public void reset()
    {
        destroy();
        _isInited = true;

        r = new float[_numCells];
        rOld = new float[_numCells];

        g = new float[_numCells];
        gOld = new float[_numCells];

        b = new float[_numCells];
        bOld = new float[_numCells];

        u = new float[_numCells];
        uOld = new float[_numCells];
        v = new float[_numCells];
        vOld = new float[_numCells];

        for (int i = 0; i < _numCells; i++)
        {
            u[i] = uOld[i] = v[i] = vOld[i] = 0.0f;
            r[i] = rOld[i] = g[i] = gOld[i] = b[i] = bOld[i] = 0;
        }
    }

    /**
	 * (INFO) get fluid cell index for (i,j) cell coordinates
	 * @param i fluid cell index in x direction
	 * @param j fluid cell index in y direction
	 * @return cell index (to be used in r, g, b, u, v arrays)
	 */
    public int getIndexForCellPosition(int i, int j)
    {
        if (i < 1) i = 1; else if (i > _NX) i = _NX;
        if (j < 1) j = 1; else if (j > _NY) j = _NY;
        return FLUID_IX(i, j);
    }

    /**
	 * (INFO) get fluid cell index for normalized (x, y) coordinates
	 * @param x 0...1 normalized x position
	 * @param y 0...1 normalized y position
	 * @return cell index (to be used in r, g, b, u, v arrays)
	 */
    public int getIndexForNormalizedPosition(float x, float y)
    {
        return getIndexForCellPosition((int)Mathf.Floor(x * (_NX + 2)), (int)Mathf.Floor(y * (_NY + 2)));
    }


    /**
	 * (INFO) whether the solver has been setup or not
	 */
    public bool isInited()
    {
        return _isInited;
    }


    /**
	 * (INFO) return total number of cells (_NX+2) * (_NY+2)
	*/
    public int getNumCells()
    {
        return _numCells;
    }

    /**
	 * (INFO) return number of cells in x direction (_NX+2)
	*/
    public int getWidth()
    {
        return _NX + 2;
    }

    /**
	 * (INFO) return number of cells in y direction (_NY+2)
	*/
    public int getHeight()
    {
        return _NY + 2;
    }

    /**
	 * (INFO) return viscosity
	*/
    public float getVisc()
    {
        return visc;
    }

    /**
	 * (INFO) return average density of fluid
	*/
    public float getAvgDensity()
    {
        return _avgDensity;
    }

    /**
	 * (INFO) return average uniformity (distribution of densities and dye)
	*/
    public float getUniformity()
    {
        return uniformity;
    }

    /**
	 * (INFO) return average speed of fluid
	*/
    public float getAvgSpeed()
    {
        return _avgSpeed;
    }

    /**
	 * this must be called once every frame to move the solver one step forward 
	 * i.e. in your sketch draw() method
	*/
    public void update()
    {
        //		ADD_SOURCE_UV();
        addSourceUV();

        swapU();
        swapV();

        //		DIFFUSE_UV();
        diffuseUV(0, visc);

        project(u, v, uOld, vOld);

        swapU();
        swapV();

        advect(1, u, uOld, uOld, vOld);
        advect(2, v, vOld, uOld, vOld);

        project(u, v, uOld, vOld);

        if (_isRGB)
        {
            //ADD_SOURCE_RGB();
            addSourceRGB();
            swapRGB();

            //DIFFUSE_RGB();
            diffuseRGB(0, 0);
            swapRGB();

            //ADVECT_RGB();
            advectRGB(0, u, v);

            fadeRGB();
        }
        else
        {
            addSource(r, rOld);
            swapR();

            diffuse(0, r, rOld, 0);
            swapRGB();

            advect(0, r, rOld, u, v);
            fadeR();
        }
    }


    protected void fadeR()
    {
        // I want the fluid to gradually fade out so the screen doesn't fill. the amount it fades out depends on how full it is, and how uniform (i.e. boring) the fluid is...
        //		float holdAmount = 1 - _avgDensity * _avgDensity * _fadeSpeed;	// this is how fast the density will decay depending on how full the screen currently is
        float holdAmount = 1 - _fadeSpeed;

        _avgDensity = 0;
        _avgSpeed = 0;

        float totalDeviations = 0;
        float currentDeviation;
        //	float uniformityMult = uniformity * 0.05f;

        _avgSpeed = 0;
        for (int i = 0; i < _numCells; i++)
        {
            // clear old values
            uOld[i] = vOld[i] = 0;
            rOld[i] = 0;
            //		gOld[i] = bOld[i] = 0;

            // calc avg speed
            _avgSpeed += u[i] * u[i] + v[i] * v[i];

            // calc avg density
            r[i] = Mathf.Min(1.0f, r[i]);
            //		g[i] = Math.min(1.0f, g[i]);
            //		b[i] = Math.min(1.0f, b[i]);
            //		float density = Math.max(r[i], Math.max(g[i], b[i]));
            float density = r[i];
            _avgDensity += density; // add it up

            // calc deviation (for uniformity)
            currentDeviation = density - _avgDensity;
            totalDeviations += currentDeviation * currentDeviation;

            // fade out old
            r[i] *= holdAmount;
        }
        _avgDensity *= _invNumCells;
        //	_avgSpeed *= _invNumCells;

        //	println("%.3f\n", _avgSpeed);
        uniformity = 1.0f / (1 + totalDeviations * _invNumCells);       // 0: very wide distribution, 1: very uniform
    }


    protected void fadeRGB()
    {
        // I want the fluid to gradually fade out so the screen doesn't fill. the amount it fades out depends on how full it is, and how uniform (i.e. boring) the fluid is...
        //		float holdAmount = 1 - _avgDensity * _avgDensity * _fadeSpeed;	// this is how fast the density will decay depending on how full the screen currently is
        float holdAmount = 1 - _fadeSpeed;

        _avgDensity = 0;
        _avgSpeed = 0;

        float totalDeviations = 0;
        float currentDeviation;
        //	float uniformityMult = uniformity * 0.05f;

        _avgSpeed = 0;
        for (int i = 0; i < _numCells; i++)
        {
            // clear old values
            uOld[i] = vOld[i] = 0;
            rOld[i] = 0;
            gOld[i] = bOld[i] = 0;

            // calc avg speed
            _avgSpeed += u[i] * u[i] + v[i] * v[i];

            // calc avg density
            r[i] = Mathf.Min(1.0f, r[i]);
            g[i] = Mathf.Min(1.0f, g[i]);
            b[i] = Mathf.Min(1.0f, b[i]);
            float density = Mathf.Max(r[i], Mathf.Max(g[i], b[i]));
            //float density = r[i];
            _avgDensity += density; // add it up

            // calc deviation (for uniformity)
            currentDeviation = density - _avgDensity;
            totalDeviations += currentDeviation * currentDeviation;

            // fade out old
            r[i] *= holdAmount;
            g[i] *= holdAmount;
            b[i] *= holdAmount;

        }
        _avgDensity *= _invNumCells;
        _avgSpeed *= _invNumCells;

        //println("%.3f\n", _avgDensity);
        uniformity = 1.0f / (1 + totalDeviations * _invNumCells);       // 0: very wide distribution, 1: very uniform
    }


    protected void addSourceUV()
    {
        for (int i = 0; i < _numCells; i++)
        {
            u[i] += _dt * uOld[i];
            v[i] += _dt * vOld[i];
        }
    }

    protected void addSourceRGB()
    {
        for (int i = 0; i < _numCells; i++)
        {
            r[i] += _dt * rOld[i];
            g[i] += _dt * gOld[i];
            b[i] += _dt * bOld[i];
        }
    }



    protected void addSource(float[] x, float[] x0)
    {
        for (int i = 0; i < _numCells; i++)
        {
            x[i] += _dt * x0[i];
        }
    }


    protected void advect(int b, float[] _d, float[] d0, float[] du, float[] dv)
    {
        int i0, j0, i1, j1;
        float x, y, s0, t0, s1, t1, dt0;

        dt0 = _dt * _NX;

        for (int i = 1; i <= _NX; i++)
        {
            for (int j = 1; j <= _NY; j++)
            {
                x = i - dt0 * du[FLUID_IX(i, j)];
                y = j - dt0 * dv[FLUID_IX(i, j)];

                if (x > _NX + 0.5) x = _NX + 0.5f;
                if (x < 0.5) x = 0.5f;

                i0 = (int)x;
                i1 = i0 + 1;

                if (y > _NY + 0.5) y = _NY + 0.5f;
                if (y < 0.5) y = 0.5f;

                j0 = (int)y;
                j1 = j0 + 1;

                s1 = x - i0;
                s0 = 1 - s1;
                t1 = y - j0;
                t0 = 1 - t1;

                _d[FLUID_IX(i, j)] = s0 * (t0 * d0[FLUID_IX(i0, j0)] + t1 * d0[FLUID_IX(i0, j1)])
                + s1 * (t0 * d0[FLUID_IX(i1, j0)] + t1 * d0[FLUID_IX(i1, j1)]);

            }
        }
        setBoundary(b, _d);
    }

    protected void advectRGB(int bound, float[] du, float[] dv)
    {
        int i0, j0, i1, j1;
        float x, y, s0, t0, s1, t1, dt0;

        dt0 = _dt * _NX;

        for (int i = 1; i <= _NX; i++)
        {
            for (int j = 1; j <= _NY; j++)
            {
                x = i - dt0 * du[FLUID_IX(i, j)];
                y = j - dt0 * dv[FLUID_IX(i, j)];

                if (x > _NX + 0.5) x = _NX + 0.5f;
                if (x < 0.5) x = 0.5f;

                i0 = (int)x;
                i1 = i0 + 1;

                if (y > _NY + 0.5) y = _NY + 0.5f;
                if (y < 0.5) y = 0.5f;

                j0 = (int)y;
                j1 = j0 + 1;

                s1 = x - i0;
                s0 = 1 - s1;
                t1 = y - j0;
                t0 = 1 - t1;

                r[FLUID_IX(i, j)] = s0 * (t0 * rOld[FLUID_IX(i0, j0)] + t1 * rOld[FLUID_IX(i0, j1)]) + s1 * (t0 * rOld[FLUID_IX(i1, j0)] + t1 * rOld[FLUID_IX(i1, j1)]);
                g[FLUID_IX(i, j)] = s0 * (t0 * gOld[FLUID_IX(i0, j0)] + t1 * gOld[FLUID_IX(i0, j1)]) + s1 * (t0 * gOld[FLUID_IX(i1, j0)] + t1 * gOld[FLUID_IX(i1, j1)]);
                b[FLUID_IX(i, j)] = s0 * (t0 * bOld[FLUID_IX(i0, j0)] + t1 * bOld[FLUID_IX(i0, j1)]) + s1 * (t0 * bOld[FLUID_IX(i1, j0)] + t1 * bOld[FLUID_IX(i1, j1)]);
            }
        }
        setBoundaryRGB(bound);
    }



    protected void diffuse(int b, float[] c, float[] c0, float _diff)
    {
        float a = _dt * _diff * _NX * _NY;
        linearSolver(b, c, c0, a, 1.0f + 4 * a);
    }

    protected void diffuseRGB(int b, float _diff)
    {
        float a = _dt * _diff * _NX * _NY;
        linearSolverRGB(b, a, 1.0f + 4 * a);
    }

    protected void diffuseUV(int b, float _diff)
    {
        float a = _dt * _diff * _NX * _NY;
        linearSolverUV(b, a, 1.0f + 4 * a);
    }


    protected void project(float[] x, float[] y, float[] p, float[] div)
    {
        for (int i = 1; i <= _NX; i++)
        {
            for (int j = 1; j <= _NY; j++)
            {
                div[FLUID_IX(i, j)] = (x[FLUID_IX(i + 1, j)] - x[FLUID_IX(i - 1, j)] + y[FLUID_IX(i, j + 1)] - y[FLUID_IX(i, j - 1)])
                * -0.5f / _NX;
                p[FLUID_IX(i, j)] = 0;
            }
        }

        setBoundary(0, div);
        setBoundary(0, p);

        linearSolver(0, p, div, 1, 4);

        for (int i = 1; i <= _NX; i++)
        {
            for (int j = 1; j <= _NY; j++)
            {
                x[FLUID_IX(i, j)] -= 0.5f * _NX * (p[FLUID_IX(i + 1, j)] - p[FLUID_IX(i - 1, j)]);
                y[FLUID_IX(i, j)] -= 0.5f * _NX * (p[FLUID_IX(i, j + 1)] - p[FLUID_IX(i, j - 1)]);
            }
        }

        setBoundary(1, x);
        setBoundary(2, y);
    }



    protected void linearSolver(int b, float[] x, float[] x0, float a, float c)
    {
        for (int k = 0; k < _solverIterations; k++)
        {
            for (int i = 1; i <= _NX; i++)
            {
                for (int j = 1; j <= _NY; j++)
                {
                    x[FLUID_IX(i, j)] = (a * (x[FLUID_IX(i - 1, j)] + x[FLUID_IX(i + 1, j)] + x[FLUID_IX(i, j - 1)] + x[FLUID_IX(i, j + 1)]) + x0[FLUID_IX(i, j)]) / c;
                }
            }
            setBoundary(b, x);
        }
    }

    //#define LINEAR_SOLVE_EQ	(x, x0)			(a * ( x[] + x[]  +  x[] + x[])  +  x0[]) / c;

    protected void linearSolverRGB(int bound, float a, float c)
    {
        int index1, index2, index3, index4, index5;
        for (int k = 0; k < _solverIterations; k++)
        {       // MEMO
            for (int i = 1; i <= _NX; i++)
            {
                for (int j = 1; j <= _NY; j++)
                {
                    index5 = FLUID_IX(i, j);
                    index1 = index5 - 1;//FLUID_IX(i-1, j);
                    index2 = index5 + 1;//FLUID_IX(i+1, j);
                    index3 = index5 - (_NX + 2);//FLUID_IX(i, j-1);
                    index4 = index5 + (_NX + 2);//FLUID_IX(i, j+1);

                    r[index5] = (a * (r[index1] + r[index2] + r[index3] + r[index4]) + rOld[index5]) / c;
                    g[index5] = (a * (g[index1] + g[index2] + g[index3] + g[index4]) + gOld[index5]) / c;
                    b[index5] = (a * (b[index1] + b[index2] + b[index3] + b[index4]) + bOld[index5]) / c;
                    //				x[FLUID_IX(i, j)] = (a * ( x[FLUID_IX(i-1, j)] + x[FLUID_IX(i+1, j)]  +  x[FLUID_IX(i, j-1)] + x[FLUID_IX(i, j+1)])  +  x0[FLUID_IX(i, j)]) / c;
                }
            }
            setBoundaryRGB(bound);
        }
    }

    protected void linearSolverUV(int bound, float a, float c)
    {
        int index1, index2, index3, index4, index5;
        for (int k = 0; k < _solverIterations; k++)
        {       // MEMO
            for (int i = 1; i <= _NX; i++)
            {
                for (int j = 1; j <= _NY; j++)
                {
                    index5 = FLUID_IX(i, j);
                    index1 = index5 - 1;//FLUID_IX(i-1, j);
                    index2 = index5 + 1;//FLUID_IX(i+1, j);
                    index3 = index5 - (_NX + 2);//FLUID_IX(i, j-1);
                    index4 = index5 + (_NX + 2);//FLUID_IX(i, j+1);

                    u[index5] = (a * (u[index1] + u[index2] + u[index3] + u[index4]) + uOld[index5]) / c;
                    v[index5] = (a * (v[index1] + v[index2] + v[index3] + v[index4]) + vOld[index5]) / c;
                    //				x[FLUID_IX(i, j)] = (a * ( x[FLUID_IX(i-1, j)] + x[FLUID_IX(i+1, j)]  +  x[FLUID_IX(i, j-1)] + x[FLUID_IX(i, j+1)])  +  x0[FLUID_IX(i, j)]) / c;
                }
            }
            setBoundaryRGB(bound);
        }
    }



    protected void setBoundary(int b, float[] x)
    {
        return;
        for (int i = 1; i <= _NX; i++)
        {
            if (i <= _NY)
            {
                x[FLUID_IX(0, i)] = b == 1 ? -x[FLUID_IX(1, i)] : x[FLUID_IX(1, i)];
                x[FLUID_IX(_NX + 1, i)] = b == 1 ? -x[FLUID_IX(_NX, i)] : x[FLUID_IX(_NX, i)];
            }

            x[FLUID_IX(i, 0)] = b == 2 ? -x[FLUID_IX(i, 1)] : x[FLUID_IX(i, 1)];
            x[FLUID_IX(i, _NY + 1)] = b == 2 ? -x[FLUID_IX(i, _NY)] : x[FLUID_IX(i, _NY)];
        }

        x[FLUID_IX(0, 0)] = 0.5f * (x[FLUID_IX(1, 0)] + x[FLUID_IX(0, 1)]);
        x[FLUID_IX(0, _NY + 1)] = 0.5f * (x[FLUID_IX(1, _NY + 1)] + x[FLUID_IX(0, _NY)]);
        x[FLUID_IX(_NX + 1, 0)] = 0.5f * (x[FLUID_IX(_NX, 0)] + x[FLUID_IX(_NX + 1, 1)]);
        x[FLUID_IX(_NX + 1, _NY + 1)] = 0.5f * (x[FLUID_IX(_NX, _NY + 1)] + x[FLUID_IX(_NX + 1, _NY)]);
    }


    protected void setBoundaryRGB(int bound)
    {
        return;
        int index1, index2;
        for (int i = 1; i <= _NX; i++)
        {
            if (i <= _NY)
            {
                index1 = FLUID_IX(0, i);
                index2 = FLUID_IX(1, i);
                r[index1] = bound == 1 ? -r[index2] : r[index2];
                g[index1] = bound == 1 ? -g[index2] : g[index2];
                b[index1] = bound == 1 ? -b[index2] : b[index2];

                index1 = FLUID_IX(_NX + 1, i);
                index2 = FLUID_IX(_NX, i);
                r[index1] = bound == 1 ? -r[index2] : r[index2];
                g[index1] = bound == 1 ? -g[index2] : g[index2];
                b[index1] = bound == 1 ? -b[index2] : b[index2];
            }

            index1 = FLUID_IX(i, 0);
            index2 = FLUID_IX(i, 1);
            r[index1] = bound == 2 ? -r[index2] : r[index2];
            g[index1] = bound == 2 ? -g[index2] : g[index2];
            b[index1] = bound == 2 ? -b[index2] : b[index2];

            index1 = FLUID_IX(i, _NY + 1);
            index2 = FLUID_IX(i, _NY);
            r[index1] = bound == 2 ? -r[index2] : r[index2];
            g[index1] = bound == 2 ? -g[index2] : g[index2];
            b[index1] = bound == 2 ? -b[index2] : b[index2];

        }

        //	x[FLUID_IX(  0,   0)] = 0.5f * (x[FLUID_IX(1, 0  )] + x[FLUID_IX(  0, 1)]);
        //	x[FLUID_IX(  0, _NY+1)] = 0.5f * (x[FLUID_IX(1, _NY+1)] + x[FLUID_IX(  0, _NY)]);
        //	x[FLUID_IX(_NX+1,   0)] = 0.5f * (x[FLUID_IX(_NX, 0  )] + x[FLUID_IX(_NX+1, 1)]);
        //	x[FLUID_IX(_NX+1, _NY+1)] = 0.5f * (x[FLUID_IX(_NX, _NY+1)] + x[FLUID_IX(_NX+1, _NY)]);

    }


    protected void swapU()
    {
        _tmp = u;
        u = uOld;
        uOld = _tmp;
    }
    protected void swapV()
    {
        _tmp = v;
        v = vOld;
        vOld = _tmp;
    }
    protected void swapR()
    {
        _tmp = r;
        r = rOld;
        rOld = _tmp;
    }

    protected void swapRGB()
    {
        _tmp = r;
        r = rOld;
        rOld = _tmp;

        _tmp = g;
        g = gOld;
        gOld = _tmp;

        _tmp = b;
        b = bOld;
        bOld = _tmp;
    }



    protected float width;
    protected float height;
    protected float invWidth;
    protected float invHeight;

    protected int _NX, _NY, _numCells;
    protected float _invNX, _invNY, _invNumCells;
    protected float _dt;
    protected bool _isInited;
    protected bool _isRGB;               // for monochrome, only update r
    protected int _solverIterations;

    protected float visc;
    protected float _fadeSpeed;

    protected float[] _tmp;

    protected float _avgDensity;            // this will hold the average color of the last frame (how full it is)
    protected float uniformity;         // this will hold the uniformity of the last frame (how uniform the color is);
    protected float _avgSpeed;

    // These were #defines in c++ version
    protected int FLUID_IX(int i, int j) { return ((i) + (_NX + 2) * (j)); }
}

