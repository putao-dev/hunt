/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.http.request;

import collie.codec.http;

import hunt.http.webfrom;
import hunt.http.session;
import hunt.http.sessionstorage;
import hunt.http.cookie;

import std.string;

class Request
{
    this(HTTPRequest req)
    {
        assert(req);
        _req = req;
    }

    @property WebForm postForm()
    {
        if (_form is null)
            _form = new WebForm(_req);
        return _form;
    }

    alias httpRequest this;

    @property httpRequest()
    {
        return _req;
    }

    @property mate()
    {
        return _mate;
    }

    string getMate(string key)
    {
        return _mate.get(key, "");
    }

    void addMate(string key, string value)
    {
        _mate[key] = value;
    }

	SessionInterface getSession( S = Session)(string sessionName = "hunt_session", SessionStorageInterface t =  newStorage()) //if()
	{
		auto co = getCookie(sessionName);
		if (co is null) return new S(t);
		return new S(co.value, t);
	}

	Cookie getCookie(string key)
	{
		if(cookies.length == 0)
		{
			string cookie = this._req.Header.getHeaderValue("cookie");
			cookies = parseCookie(cookie);
		}
		return cookies.get(key,null);
	}
	
	string getCookieValue(string key)
     	{
	         auto cookie = this.getCookie(key);
	         if(cookie is null)
	         {
	             return ""; 
	         }
	         return cookie.value;
     	}

    ///get queries
    @property string[string] queries()
    {
        if(_queries is null)
        {
            _queries = _req.Header.queryMap();
        }
        return _queries;
    }
	/// get a query
    T get(T = string)(string key, T v = T.init)
    {
        import std.conv;
        auto tmp = this.queries;
        if(tmp is null)
        {
            return v;   
        }
        auto _v = tmp.get(key, "");
        if(_v.length)
        {
            return to!T(_v);
        }
        return v;
    }

    @property string clientIp()
    {
        string XFF = this._req.Header.getHeaderValue("X-Forwarded-For");
        string[] xff_arr = split(XFF,", ");
        if(xff_arr.length > 0)
        {
            return xff_arr[0];
        }
        string XRealIP = this._req.Header.getHeaderValue("X-Real-IP");
        if(XRealIP.length > 0)
        {
            return XRealIP;
        }
        return this.clientAddress.toAddrString();
    }

    /// get a post
    T post(T = string)(string key, T v = T.init)
    {
        import std.conv;
        auto tmp = this.postForm.formMap();
        if(tmp is null)
        {
            return v;   
        }
        auto _v = tmp.get(key, "");
        if(_v.length)
        {
            return to!T(_v);
        }
        return v;
    }

    @property ref string[string] materef() {return _mate;}
private:
    HTTPRequest _req;
    WebForm _form = null;
    string[string] _mate;
    SessionInterface session;
    Cookie[string] cookies;
    string[string] _queries;
}
