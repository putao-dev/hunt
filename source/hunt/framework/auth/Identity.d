module hunt.framework.auth.Identity;

import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.principal;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.base64;
import std.string;
import std.variant;

/**
 * User Identity
 */
class Identity {
    private Subject _subject;

    this(string guardName) {
        _subject = SecurityUtils.getSubject(guardName);
    }

    ulong id() {
        PrincipalCollection pCollection = _subject.getPrincipals();
        UserIdPrincipal principal = PrincipalCollectionHelper.oneByType!(UserIdPrincipal)(pCollection);

        if(principal is null) {
            return 0;
        } else {
            return principal.getUserId();
        }        
    }

    string name() {
        PrincipalCollection pCollection = _subject.getPrincipals();
        UsernamePrincipal principal = PrincipalCollectionHelper.oneByType!(UsernamePrincipal)(pCollection);

        if(principal is null) {
            return "";
        } else {
            return principal.getUsername();
        }
    }
    
    AuthenticationScheme authScheme() {
        Variant var = claim(ClaimTypes.AuthScheme);
        if(var == null) return AuthenticationScheme.None;
        return cast(AuthenticationScheme)var.get!string();
    }

    Variant claim(string type) {
        PrincipalCollection pCollection = _subject.getPrincipals();
        Variant v = Variant(null);

        foreach(Object p; pCollection) {
            Claim claim = cast(Claim)p;
            if(claim is null) continue;
            if(claim.type == type) {
                v = claim.value();
                break;
            }
        }
        return v;
    }
    
    T claimAs(T)(string type) {
        Variant v = claim(type);
        if(v == null || !v.hasValue()) {
            version(HUNT_DEBUG) warningf("The claim for %s is null", type);
            return T.init;
        }

        return v.get!T();
    }

    Claim[] claims() {
        Claim[] r;

        PrincipalCollection pCollection = _subject.getPrincipals();
        foreach(Object p; pCollection) {
            Claim claim = cast(Claim)p;
            if(claim is null) continue;
            r ~= claim;
        }

        return r;
    }

    void authenticate(string username, string password, bool remember = true, 
            string tokenName = DEFAULT_AUTH_TOKEN_NAME) {

        version(HUNT_SHIRO_DEBUG) { 
            tracef("Checking the status at first: %s", _subject.isAuthenticated());
        }

        if (_subject.isAuthenticated()) {
            _subject.logout();
        }

        UsernamePasswordToken token = new UsernamePasswordToken(username, password);
        token.setRememberMe(remember);
        token.name = tokenName;

        try {
            _subject.login(token);
        } catch (UnknownAccountException ex) {
            info("There is no user with username of " ~ token.getPrincipal());
        } catch (IncorrectCredentialsException ex) {
            info("Password for account " ~ token.getPrincipal() ~ " was incorrect!");
        } catch (LockedAccountException ex) {
            info("The account for username " ~ token.getPrincipal()
                    ~ " is locked.  " ~ "Please contact your administrator to unlock it.");
        } catch (AuthenticationException ex) {
            errorf("Authentication failed: ", ex.msg);
            version(HUNT_DEBUG) error(ex);
        } catch (Exception ex) {
            errorf("Authentication failed: ", ex.msg);
            version(HUNT_DEBUG) error(ex);
        }
    }

    void authenticate(string token, string tokenName, AuthenticationScheme scheme) {
        version(HUNT_AUTH_DEBUG) {
            infof("tokenName: %s, scheme: %s", tokenName, scheme);
        }

        if(scheme == AuthenticationScheme.Bearer) {
            bearerLogin(token, tokenName);
        } else if(scheme == AuthenticationScheme.Basic) {
            basicLogin(token, tokenName);
        } else {
            warningf("Unknown AuthenticationScheme: %s", scheme);
        }
    }


    private void basicLogin(string tokenString, string tokenName = DEFAULT_AUTH_TOKEN_NAME) {
        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong token: %s", values);
            return;
        }

        string username = values[0];
        string password = values[1];
        authenticate(username, password, true, tokenName);
    }

    private void bearerLogin(string tokenString, string tokenName = DEFAULT_AUTH_TOKEN_NAME) {
        try {
            JwtToken token = new JwtToken(tokenString, tokenName);
            _subject.login(token);
        } catch (AuthenticationException e) {
            warning(e.msg);
            version(HUNT_AUTH_DEBUG) warning(e);
        } catch(Exception ex) {
            warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
        }
    }

    bool isAuthenticated() {
        return _subject.isAuthenticated();
    }

    bool hasRole(string role) {
        return _subject.hasRole(role);
    }
    
    bool hasAllRoles(string[] roles...) {
        return _subject.hasAllRoles(roles);
    }

    bool isPermitted(string[] permissions...) {
        bool[] resultSet = _subject.isPermitted(permissions);
        foreach(bool r; resultSet ) {
            if(!r) return false;
        }

        return true;
    }

    void logout() {
        _subject.logout();
    }

    override string toString() {
        return name(); 
    }
}
