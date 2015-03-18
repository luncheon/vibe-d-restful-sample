var client = (function () {
    'use strict';

    var request = function (url, method, data) {
        return $.ajax({
            url:         url,
            type:        method,
            data:        data ? JSON.stringify(data) : '',
            contentType: 'application/json',
            dataType:    'json',
            cache:       false,
        }).fail(function (xhr, status, thrown) {
            console.error({xhr: xhr, status: status, thrown: thrown}, xhr.responseText);
            alert(thrown);
        });
    }

    this.RestClient = function (baseurl) {
        this.get    = function ()         { return request(baseurl,            'GET'); }
        this.delete = function (id)       { return request(baseurl + '/' + id, 'DELETE'); }
        this.create = function (data)     { return request(baseurl,            'POST', data); }
        this.update = function (id, data) { return request(baseurl + '/' + id, 'PUT', data); }

        this.login  = function (data) {
            return $.post('login', data).done(function (data, status, xhr) {
                var cookie = xhr.getResponseHeader('Set-Cookie');
                if (cookie) {
                    document.cookie = cookie;
                }
                location.reload();
            }).fail(function () { alert('login failure'); });
        }
        this.logout = function () {
            return $.post('logout').then(function () { location.reload(); });
        }
    }

    var find = function (array, id) {
        for (var i = 0, len = array.length; i < len; i++) {
            if (array[i].id === id) {
                return array[i];
            }
        }
        return null;
    }

    var resolve = function (data) {
        var deferred = new $.Deferred;
        deferred.resolve(data);
        return deferred.promise();
    }

    var reject = function (data) {
        var deferred = new $.Deferred;
        deferred.reject(data);
        alert(data);
        return deferred.promise();
    }

    this.LocalStorage = function (baseurl) {
        this.load = function () {
            return JSON.parse(localStorage.getItem(baseurl)) || [];
        }
        this.save = function (items) {
            localStorage.setItem(baseurl, JSON.stringify(items));
        }
        this.get = function (id) {
            if (id) {
                var found = find(this.load(), id);
                return found ? resolve(found) : reject('Not Found');
            }
            return resolve(this.load());
        }
        this.delete = function (id) {
            this.save(this.load().filter(function (item) { return item.id !== id; }));
            return resolve();
        }
        this.create = function (data) {
            if (!data || !data.id || !data.name) {
                return reject('Bad Request');
            }
            var items = this.load();
            if (find(items, data.id)) {
                return reject('Conflict');
            }
            items.push(data);
            this.save(items);
            return resolve();
        }
        this.update = function (id, data) {
            var items = this.load();
            var item = find(items, id);
            if (!item) {
                return reject('Not Found');
            }
            if (data.id && data.id !== id && find(items, data.id)) {
                return reject('Conflict');
            }
            for (var key in item) {
                item[key] = data[key] || item[key];
            }
            this.save(items);
            return resolve();
        }
        this.getSessionUser = function () {
            return JSON.parse(sessionStorage.getItem('user'));
        }
        this.login = function (data) {
            var user = find(this.load(), data.id);
            if (user && user.password === data.password) {
                sessionStorage.setItem('user', JSON.stringify(user));
                location.reload();
                return resolve();
            } else {
                return reject('login failure');
            }
        }
        this.logout = function () {
            sessionStorage.clear();
            location.reload();
            return resolve();
        }
    }

    return this;
}).apply(this.client || {});
