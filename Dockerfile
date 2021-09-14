FROM public.ecr.aws/amazonlinux/amazonlinux:2 as build-stage
RUN rpm --rebuilddb && yum install -y yum-plugin-ovl openssl-devel
RUN yum groupinstall -y "Development tools"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN source $HOME/.cargo/env && rustup target add x86_64-unknown-linux-musl
RUN curl -o /musl-1.2.2.tar.gz https://musl.libc.org/releases/musl-1.2.2.tar.gz \
    && tar zxf /musl-1.2.2.tar.gz && cd musl-1.2.2/ \
    && ./configure && make install && ln -s /usr/local/musl/bin/musl-gcc /usr/local/bin
WORKDIR /app
ADD . /app
RUN source $HOME/.cargo/env && CC=musl-gcc cargo build --release --target=x86_64-unknown-linux-musl --features vendored

FROM scratch AS package-stage
COPY --from=build-stage /app/target/x86_64-unknown-linux-musl/release/bootstrap /opt/bootstrap
