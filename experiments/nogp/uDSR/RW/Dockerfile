FROM tpsr AS builder

WORKDIR /root/deep-symbolic-optimization

SHELL ["/bin/bash", "--login", "-c"]

ENV PATH="/root/anaconda3/bin:$PATH"

RUN source /root/anaconda3/etc/profile.d/conda.sh && conda activate tpsr && ./runRW.sh 

FROM scratch AS exporter

COPY --from=builder /root/deep-symbolic-optimization/*.gz .
