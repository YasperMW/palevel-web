(function(){
    var rootEl;
    var titleEl;
    var messageEl;
    var okBtn;
    var cancelBtn;
    var closeEls;

    var isOpen = false;
    var lastActiveEl = null;
    var resolveCurrent = null;
    var rejectCurrent = null;

    function getEl(){
        if (rootEl) return;
        rootEl = document.getElementById('palevel-dialog');
        if (!rootEl) return;
        titleEl = document.getElementById('palevel-dialog-title');
        messageEl = document.getElementById('palevel-dialog-message');
        okBtn = rootEl.querySelector('[data-palevel-dialog-ok]');
        cancelBtn = rootEl.querySelector('[data-palevel-dialog-cancel]');
        closeEls = rootEl.querySelectorAll('[data-palevel-dialog-close]');

        if (okBtn) {
            okBtn.addEventListener('click', function(){ close(true); });
        }
        if (cancelBtn) {
            cancelBtn.addEventListener('click', function(){ close(false); });
        }
        if (closeEls && closeEls.length) {
            closeEls.forEach(function(el){
                el.addEventListener('click', function(){ close(false); });
            });
        }

        document.addEventListener('keydown', function(e){
            if (!isOpen) return;
            if (e.key === 'Escape') {
                e.preventDefault();
                close(false);
                return;
            }
            if (e.key === 'Tab') {
                trapFocus(e);
            }
        });

        document.addEventListener('click', function(e){
            if (!isOpen) return;
            var t = e.target;
            if (!t) return;
            var confirmForm = t.closest && t.closest('form[data-palevel-confirm]');
            if (!confirmForm) return;

            if (t.matches('button[type="submit"], input[type="submit"]') || t.closest('button[type="submit"], input[type="submit"]')) {
                e.preventDefault();
                e.stopPropagation();

                var msg = confirmForm.getAttribute('data-palevel-confirm') || 'Are you sure?';
                window.PalevelDialog.confirm(msg).then(function(ok){
                    if (ok) confirmForm.submit();
                });
            }
        }, true);

        document.addEventListener('submit', function(e){
            var form = e.target;
            if (!form || !form.getAttribute) return;
            var msg = form.getAttribute('data-palevel-confirm');
            if (!msg) return;

            e.preventDefault();
            e.stopPropagation();
            window.PalevelDialog.confirm(msg).then(function(ok){
                if (ok) form.submit();
            });
        }, true);
    }

    function open(options){
        getEl();
        if (!rootEl) {
            return Promise.resolve(false);
        }

        if (resolveCurrent) {
            close(false);
        }

        options = options || {};

        lastActiveEl = document.activeElement;
        isOpen = true;

        titleEl.textContent = options.title || 'Message';
        messageEl.textContent = options.message || '';

        okBtn.textContent = options.okText || 'OK';
        cancelBtn.textContent = options.cancelText || 'Cancel';

        cancelBtn.style.display = options.showCancel ? '' : 'none';

        okBtn.classList.remove('palevel-dialog__btn--danger');
        if (options.variant === 'danger') {
            okBtn.classList.add('palevel-dialog__btn--danger');
        }

        rootEl.classList.remove('hidden');
        rootEl.setAttribute('aria-hidden', 'false');

        setTimeout(function(){
            try { okBtn.focus(); } catch(e) {}
        }, 0);

        return new Promise(function(resolve, reject){
            resolveCurrent = resolve;
            rejectCurrent = reject;
        });
    }

    function close(result){
        if (!isOpen) return;
        isOpen = false;

        if (rootEl) {
            rootEl.classList.add('hidden');
            rootEl.setAttribute('aria-hidden', 'true');
        }

        if (resolveCurrent) {
            var r = resolveCurrent;
            resolveCurrent = null;
            rejectCurrent = null;
            r(!!result);
        }

        if (lastActiveEl && lastActiveEl.focus) {
            try { lastActiveEl.focus(); } catch(e) {}
        }
        lastActiveEl = null;
    }

    function trapFocus(e){
        if (!rootEl) return;
        var focusables = rootEl.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        if (!focusables.length) return;

        var first = focusables[0];
        var last = focusables[focusables.length - 1];
        var active = document.activeElement;

        if (e.shiftKey) {
            if (active === first) {
                e.preventDefault();
                last.focus();
            }
        } else {
            if (active === last) {
                e.preventDefault();
                first.focus();
            }
        }
    }

    window.PalevelDialog = {
        show: function(options){
            return open(options);
        },
        info: function(message, title){
            return open({
                title: title || 'Info',
                message: message || '',
                okText: 'OK',
                showCancel: false
            }).then(function(){ return; });
        },
        error: function(message, title){
            return open({
                title: title || 'Error',
                message: message || '',
                okText: 'OK',
                variant: 'danger',
                showCancel: false
            }).then(function(){ return; });
        },
        confirm: function(message, title, okText, cancelText){
            return open({
                title: title || 'Confirm',
                message: message || '',
                okText: okText || 'Confirm',
                cancelText: cancelText || 'Cancel',
                showCancel: true
            });
        },
        close: close
    };
})();
