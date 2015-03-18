var client = (function () {
    'use strict';

    this.RestClient = (function () {
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

        return function (baseurl) {
            this.get    = function ()         { return request(baseurl,            'GET'); }
            this.delete = function (id)       { return request(baseurl + '/' + id, 'DELETE'); }
            this.create = function (data)     { return request(baseurl,            'POST', data); }
            this.update = function (id, data) { return request(baseurl + '/' + id, 'PUT', data); }
        };
    })();

    this.LocalStorage = (function () {
        var byId = function (id) {
            return function (item) { return item.id === id; }
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

        return function (baseurl) {
            this.load = function () {
                return JSON.parse(localStorage.getItem(baseurl)) || [];
            }
            this.save = function (items) {
                localStorage.setItem(baseurl, JSON.stringify(items));
            }
            this.get = function () {
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
                if (items.some(byId(data.id))) {
                    return reject('Conflict');
                }
                items.push(data);
                this.save(items);
                return resolve();
            }
            this.update = function (id, data) {
                var items = this.load();
                var index = items.findIndex(byId(id));
                if (index === -1) {
                    return reject('Not Found');
                }
                if (data.id && data.id !== id && items.some(byId(data.id))) {
                    return reject('Conflict');
                }
                for (var key in items[index]) {
                    items[index][key] = data[key] || items[index][key];
                }
                this.save(items);
                return resolve();
            }
        }
    })();

    return this;
}).apply(this.client || {});
