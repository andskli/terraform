FROM alpine:latest

ADD ./pkg/linux_amd64/terraform /terraform

ENTRYPOINT ["/terraform"]
CMD ["help"]