NAME=git
VERSION=2.11.0
EPOCH=1
ITERATION=1
PREFIX=/usr/local/git
LICENSE=GPLv2
VENDOR="Git contributors"
MAINTAINER="Ryan Parman"
DESCRIPTION="Fast Version Control System"
URL=https://git-scm.com
RHEL=$(shell rpm -q --queryformat '%{VERSION}' centos-release)

.PHONY: package
package:
	@ echo "NAME:          $(NAME)"
	@ echo "VERSION:       $(VERSION)"
	@ echo "ITERATION:     $(ITERATION)"
	@ echo "PREFIX:        $(PREFIX)"
	@ echo "LICENSE:       $(LICENSE)"
	@ echo "VENDOR:        $(VENDOR)"
	@ echo "MAINTAINER:    $(MAINTAINER)"
	@ echo "DESCRIPTION:   $(DESCRIPTION)"
	@ echo "URL:           $(URL)"
	@ echo "RHEL:          $(RHEL)"
	@ echo " "

	rm -Rf git*
	rm -Rf /tmp/installdir*
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION)

	yum -y install \
		asciidoc \
		expat-devel \
		libcurl-devel \
		openssl-devel \
		pcre-devel \
		perl-ExtUtils-MakeMaker \
		zlib-devel \
	;

	wget https://www.kernel.org/pub/software/scm/git/$(NAME)-$(VERSION).tar.xz
	tar xf $(NAME)-$(VERSION).tar.xz
	cd ./$(NAME)-$(VERSION) && \
		./configure --prefix=$(PREFIX) \
			--with-openssl \
			--with-libpcre \
			--with-curl \
			--with-expat \
			--with-shell=$(shell which bash) \
			--with-perl=$(shell which perl) \
			--with-python=$(shell which python) \
			--with-zlib=/usr/include
	cd ./$(NAME)-$(VERSION) && \
		make prefix=$(PREFIX) all
	cd ./$(NAME)-$(VERSION) && \
		make prefix=$(PREFIX) install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION)
	cd /tmp/installdir-$(NAME)-$(VERSION) && \
		mkdir -p bin && \
		ln -s /usr/local/git/bin/git bin/git

	# Main package
	fpm \
		-d "$(NAME)-libs = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/git/bin \
		bin \
	;

	# Libs package
	fpm \
		-s dir \
		-t rpm \
		-n $(NAME)-libs \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/git/lib64 \
		usr/local/git/libexec \
	;

	# Documentation package
	fpm \
		-d "$(NAME) = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch 1 \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/git/share \
	;

	mv *.rpm /vagrant/repo/
