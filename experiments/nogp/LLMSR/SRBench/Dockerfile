FROM nongpsr AS builder

WORKDIR /root/LLM-SR

SHELL ["/bin/bash", "--login", "-c"]

ENV PATH="/root/anaconda3/bin:$PATH"

RUN ./runSRBench.sh 

FROM scratch AS exporter

COPY --from=builder /root/LLM-SR/*.gz .
