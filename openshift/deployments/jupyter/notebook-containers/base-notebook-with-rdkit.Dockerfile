FROM jupyter/base-notebook:latest

RUN conda install rdkit cairocffi && conda clean -y -a
