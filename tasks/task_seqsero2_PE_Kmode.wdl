version 1.0

task seqsero2_PE_one_sample {
  # Inputs
  input {
    File reads_1
    File reads_2
    String samplename
    String seqsero2_docker_image = "staphb/seqsero2:1.2.1"
  }

  command <<<
    # capture date and version
    # Print and save date
    date | tee DATE
    # Print and save version
    SeqSero2_package.py --version > VERSION && sed -i -e 's/^/SeqSero2_package.py /' VERSION
    # Run Kleborate on the input assembly with the --all flag and output with samplename prefix
    SeqSero2_package.py -p 8 -t 2 -m k -n ~{samplename} -d ~{samplename}_seqseqro2_output_dir -i ~{reads_1} ~{reads_2}
    # Run a python block to parse output file for terra data tables
    python3 <<CODE
    import csv
    with open("./~{samplename}_seqseqro2_output_dir/SeqSero_result.tsv",'r') as tsv_file:
      tsv_reader=csv.reader(tsv_file, delimiter="\t")
      tsv_data=list(tsv_reader)
      tsv_dict=dict(zip(tsv_data[0], tsv_data[1]))
      with open ("PREDICTED_IDENTIFICATION", 'wt') as Predicted_ID:
        pred_id=tsv_dict['Predicted identification']
        Predicted_ID.write(pred_id)
      with open ("PREDICTED_ANTIGENIC_PROFILE", 'wt') as Predicted_Antigen_Prof:
        pred_ant_prof=tsv_dict['Predicted antigenic profile']
        Predicted_Antigen_Prof.write(pred_antigen_prof)
      with open ("PREDICTED_SEROTYPE", 'wt') as Predicted_Sero:
        pred_sero=tsv_dict['Predicted serotype']
        Predicted_Sero.write(pred_sero)
      with open ("O_ANTIGEN_PREDICTION", 'wt') as O_Antigen_Pred:
        o_ant_pred=tsv_dict['O antigen prediction']
        O_Antigen_Pred.write(o_ant_pred)
      with open ("H1_ANTIGEN_PREDICTION", 'wt') as H1_Antigen_Pred:
        h1_ant_pred=tsv_dict['H1 antigen prediction(fliC)']
        H1_Antigen_Pred.write(h1_ant_pred)
      with open ("H2_ANTIGEN_PREDICTION", 'wt') as H2_Antigen_Pred:
        h2_ant_pred=tsv_dict['H2 antigen prediction(fljB)']
        H2_Antigen_Pred.write(h2_ant_pred)
      with open ("CONTAMINATION", 'wt') as Contamination_Detected:
        cont_detect=tsv_dict['Potential inter-serotype contamination']
        Contamination_Detected.write(cont_detect)
      with open ("NOTE", 'wt') as Note_Sero:
        seq_note=tsv_dict['Note']
        Note_Sero.write(seq_note)
      with open ("ANTIGENS", 'wt') as Antigens_Detected:
        antigens_list=['O antigen prediction', 'H1_ANTIGEN_PREDICTION', 'H2_ANTIGEN_PREDICTION']
        ants=[]
        for i in antigens_list:
          if tsv_dict[i] != '-':
            ants.append(tsv_dict[i])
        ants_string='/'.join(ants)
        Antigens_Detected.write(ants_string)
    CODE
  >>>
  output {
    File seqsero2_output_file = "./~{samplename}_seqseqro2_output_dir/SeqSero_result.tsv"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
    String predicted_identification = read_string("PREDICTED_IDENTIFICATION")
    String predicted_antigentic_profile = read_string("PREDICTED_ANTIGENIC_PROFILE")
    String predicted_serotype = read_string("PREDICTED_SEROTYPE")
    String o_antigen_prediction = read_string("O_ANTIGEN_PREDICTION")
    String h1_antigen_prediction = read_string("H1_ANTIGEN_PREDICTION")
    String h2_antigen_prediction = read_string("H2_ANTIGEN_PREDICTION")
    String contamination = read_string("CONTAMINATION")
    String notes = read_string("NOTE")
    String antigens = read_string("ANTIGENS")
  }
  runtime {
    docker:       "~{seqsero2_docker_image}"
    memory:       "16 GB"
    cpu:          8
    disks:        "local-disk 100 SSD"
    preemptible:  0
    maxRetries:   3
  }
}
