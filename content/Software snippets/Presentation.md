I like to have a latex/lualatex/xelatex template at hand as
* Github Copilot is able to generate new slides easily and
* I can version control my presentations

```latex
\documentclass[usenames,dvipsnames,bigger]{beamer}
\usepackage{emoji}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{fixltx2e}
\usepackage{graphicx}
\usepackage{longtable}
\usepackage{float}
\usepackage{wrapfig}
\usepackage{soul}
\usepackage{textcomp}
\usepackage{marvosym}
\usepackage{wasysym}
\usepackage{latexsym}
\usepackage{amssymb}
\usepackage{hyperref}
\usepackage{svg}
\usepackage{tikz}
\usepackage{helvet}
\usepackage{xcolor}
\usepackage{subfig}
\usepackage{fontspec}
\setmainfont{Arial}
%\renewcommand{\familydefault}{\sfdefault}

\definecolor{COLOR_BLACK_BLUE}{HTML}{CC101E}

\mode<presentation>

% Settings
\setbeamercolor*{title page header}{fg=black}
\setbeamercolor*{author}{fg=black}
\setbeamercolor*{date}{fg=black}
\setbeamercolor*{item}{fg=black}
\setbeamercolor*{frametitle}{fg=black}
\mode
<all>

\usebackgroundtemplate{

\begin{tikzpicture}[remember picture, overlay] % <------------

\node[anchor=north, inner sep=0pt] (background) at (current page.north)
     {\vbox to \paperheight{\vfil\hbox to \paperwidth{\hfil\includegraphics[width=\paperwidth]{background.png}\hfil}\vfil}};

\node[anchor=south east, inner sep=0pt] at (current page.south east)
     {\includegraphics[width=3cm]{logo.png}};
\end{tikzpicture}
}

\setbeamertemplate{itemize item}{\scriptsize$\bullet$}

\begin{document}

%----------------------------------------------

\begin{frame} %\frametitle{Models}
\label{sec-1_0}

{\huge Example: Title}
{XX, XX.XX.202X, Authors Name}

\end{frame}

%----------------------------------------------
 
\begin{frame} \frametitle{\emoji{heart} Made with \LaTeX}
     \label{sec-2_0}

     This presentation was made with \LaTeX
     
     \fbox{\includegraphics[height=4cm]{some_resource.png}}

     \begin{itemize}
          \item Github Copilot is able to assist in writing the presentation
          \item Works great for Version Control with Git
          \item Easy to ingest/interpret for future AI systems (e.g. for summarization)
     \end{itemize}
     
\end{frame}

%----------------------------------------------

\begin{frame} \frametitle{}
     \label{sec-3_1}

     {\huge Thanks for listening!}

     {XX, XX.XX.202X, Authors Name}

\end{frame}

\end{document}
```